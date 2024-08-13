import { ethers } from "hardhat";
import { toGwei } from "./encoding";
import { ExecutionMethod, PackedUserOperation, UserOperation } from "./types";
import { Signer, AddressLike, BytesLike, BigNumberish, toBeHex, concat, Provider, keccak256 } from "ethers";
import { EntryPoint } from "../../../typechain-types";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
} from "./erc7579Utils";
import { encodePacked, toBytes } from "viem";

export const DefaultsForUserOp: UserOperation = {
  sender: ethers.ZeroAddress,
  nonce: 0,
  initCode: "0x",
  callData: "0x",
  callGasLimit: 0,
  verificationGasLimit: 150000, // default verification gas. Should add create2 cost (3200+200*length) if initCode exists
  preVerificationGas: 21000, // should also cover calldata cost.
  maxFeePerGas: 0,
  maxPriorityFeePerGas: 1e9,
  paymaster: ethers.ZeroAddress,
  paymasterData: "0x",
  paymasterVerificationGasLimit: 3e5,
  paymasterPostOpGasLimit: 0,
  signature: "0x",
};

export const MODE_VALIDATION = "0x00";
export const MODE_MODULE_ENABLE = "0x01";

/**
 * Simplifies the creation of a PackedUserOperation object by abstracting repetitive logic and enhancing readability.
 * @param userOp The user operation details.
 * @returns The packed user operation object.
 */
export function buildPackedUserOp(userOp: UserOperation): PackedUserOperation {
  const {
    sender,
    nonce,
    initCode = "0x",
    callData = "0x",
    callGasLimit = 1_500_000,
    verificationGasLimit = 1_500_000,
    preVerificationGas = 2_000_000,
    maxFeePerGas = toGwei("20"),
    maxPriorityFeePerGas = toGwei("10"),
    paymaster = ethers.ZeroAddress,
    paymasterData = "0x",
    paymasterVerificationGasLimit = 3_00_000,
    paymasterPostOpGasLimit = 0,
    signature = "0x",
  } = userOp;

  // Construct the gasFees and accountGasLimits in a single step to reduce repetition
  const packedValues = packGasValues(
    callGasLimit,
    verificationGasLimit,
    maxFeePerGas,
    maxPriorityFeePerGas,
  );

  // Construct paymasterAndData only if a paymaster is specified
  // paymasterData can be generated before this stage
  let paymasterAndData: BytesLike = "0x";
  if (paymaster.toString().length >= 20 && paymaster !== ethers.ZeroAddress) {
    paymasterAndData = packPaymasterData(
      userOp.paymaster as string,
      paymasterVerificationGasLimit,
      paymasterPostOpGasLimit,
      paymasterData as string,
    );
  }

  // Return the PackedUserOperation, leveraging the simplicity of the refactored logic
  return {
    sender,
    nonce,
    initCode,
    callData,
    accountGasLimits: packedValues.accountGasLimits,
    preVerificationGas,
    gasFees: packedValues.gasFees,
    paymasterAndData,
    signature,
  };
}

/**
 * Generates a signed PackedUserOperation for testing purposes.
 * @param {UserOperation} userOp - The user operation to be signed.
 * @param {Signer} signer - The signer object to sign the operation.
 * @param {Object} setup - The setup object containing deployed contracts and addresses.
 * @param {string} [deposit] - Optional deposit amount in ETH.
 * @returns {Promise<PackedUserOperation>} A Promise that resolves to a PackedUserOperation.
 */
export async function signAndPackUserOp(
  userOp: UserOperation,
  signer: Signer, // ECDSA signer
  setup: { entryPoint: any; validator: any },
  deposit?: string,
): Promise<PackedUserOperation> {
  if (!setup.entryPoint || !setup.validator) {
    throw new Error("Setup object is missing required properties.");
  }
  if (!signer) {
    throw new Error("Signer must be provided.");
  }

  const validatorAddress = await setup.validator.getAddress();
  const nonce = await getNonce(
    setup.entryPoint,
    userOp.sender,
    MODE_VALIDATION,
    validatorAddress
  );

  userOp.nonce = nonce;
  const packedUserOp = buildPackedUserOp({
    ...userOp,
    nonce: nonce.toString(),
  });

  const userOpHash = await setup.entryPoint.getUserOpHash(packedUserOp);
  const signature = await signer.signMessage(ethers.getBytes(userOpHash));
  packedUserOp.signature = signature;

  if (deposit) {
    const depositAmount = ethers.parseEther(deposit);
    await setup.entryPoint.depositTo(userOp.sender, { value: depositAmount });
  }

  return packedUserOp;
}

export function packPaymasterData(
  paymaster: string,
  paymasterVerificationGasLimit: BigNumberish,
  postOpGasLimit: BigNumberish,
  paymasterData: BytesLike,
): BytesLike {
  return ethers.concat([
    paymaster,
    ethers.zeroPadValue(toBeHex(Number(paymasterVerificationGasLimit)), 16),
    ethers.zeroPadValue(toBeHex(Number(postOpGasLimit)), 16),
    paymasterData,
  ]);
}

export async function fillSignAndPack(
  accountAddress: AddressLike,
  initCode: BytesLike,
  callData: BytesLike,
  entryPoint: EntryPoint,
  validationMode: BytesLike,
  validatorAddress: AddressLike, // any validator
  owner: Signer, // ECDSA signer for R1/mock validator
): Promise<PackedUserOperation> {
  const nonce = await getNonce(
    entryPoint,
    accountAddress,
    validationMode,
    validatorAddress
  );
  const userOp = buildPackedUserOp({
    sender: accountAddress,
    nonce,
    initCode,
    callData,
  });
  const userOpHash = await entryPoint.getUserOpHash(userOp);
  userOp.signature = await owner.signMessage(ethers.getBytes(userOpHash));
  return userOp;
}

/**
 * Generates the full initialization code for deploying a smart account.
 * @param ownerAddress - The address of the owner of the new smart account.
 * @param factoryAddress - The address of the K1ValidatorFactory contract.
 * @param validatorAddress - The address of the module to be installed in the smart account.
 * @param saDeploymentIndex: number = 0,
 * @returns The full initialization code as a hex string.
 */
export async function getInitCode(
  ownerAddress: AddressLike,
  factoryAddress: AddressLike,
  saDeploymentIndex: number = 0,
): Promise<string> {
  // Deploy the BootstrapLib library
  const BootstrapLibFactory = await ethers.getContractFactory("BootstrapLib");
  const BootstrapLib = await BootstrapLibFactory.deploy();
  BootstrapLib.waitForDeployment();

  const K1ValidatorFactory = await ethers.getContractFactory(
    "K1ValidatorFactory",
    {
      libraries: {
        BootstrapLib: await BootstrapLib.getAddress(),
      },
    },
  );

  // Encode the createAccount function call with the provided parameters
  const factoryDeploymentData = K1ValidatorFactory.interface
    .encodeFunctionData("createAccount", [
      ownerAddress,
      saDeploymentIndex,
      [],
      0,
    ])
    .slice(2);

  return factoryAddress + factoryDeploymentData;
}

// Note: could be a method getAccountAddressAndInitCode

/**
 * Calculates the CREATE2 address for a smart account deployment.
 * @param {AddressLike} signerAddress - The address of the signer (owner of the new smart account).
 * @param {AddressLike} factoryAddress - The address of the K1ValidatorFactory contract.
 * @param {AddressLike} validatorAddress - The address of the module to be installed in the smart account.
 * @param {Object} setup - The setup object containing deployed contracts and addresses.
 * @param {number} saDeploymentIndex - The deployment index for the smart account.
 * @returns {Promise<string>} The calculated CREATE2 address.
 */
// Note: could add off-chain way later using Create2 utils
export async function getAccountAddress(
  signerAddress: AddressLike, // ECDSA signer
  factoryAddress: AddressLike,
  validatorAddress: AddressLike,
  setup: { accountFactory: any },
  saDeploymentIndex: number = 0,
): Promise<string> {
  // Module initialization data, encoded
  const moduleInitData = ethers.solidityPacked(["address"], [signerAddress]);

  setup.accountFactory = setup.accountFactory.attach(factoryAddress);

  const counterFactualAddress =
    await setup.accountFactory.computeAccountAddress(
      validatorAddress,
      moduleInitData,
      saDeploymentIndex,
    );

  return counterFactualAddress;
}

/**
 * Packs gas values into the format required by PackedUserOperation.
 * @param callGasLimit Call gas limit.
 * @param verificationGasLimit Verification gas limit.
 * @param maxFeePerGas Maximum fee per gas.
 * @param maxPriorityFeePerGas Maximum priority fee per gas.
 * @returns An object containing packed gasFees and accountGasLimits.
 */
export function packGasValues(
  callGasLimit: BigNumberish,
  verificationGasLimit: BigNumberish,
  maxFeePerGas: BigNumberish,
  maxPriorityFeePerGas: BigNumberish,
) {
  const gasFees = ethers.solidityPacked(
    ["uint128", "uint128"],
    [maxPriorityFeePerGas, maxFeePerGas],
  );
  const accountGasLimits = ethers.solidityPacked(
    ["uint128", "uint128"],
    [callGasLimit, verificationGasLimit],
  );

  return { gasFees, accountGasLimits };
}

/**
 * Generates the execution call data for a given execution method.
 * @param executionOptions - The options for the execution.
 * @param packedUserOp - The packed user operation (optional).
 * @param userOpHash - The hash of the user operation (optional).
 * @returns The execution call data as a string.
 */

// Should be able to accept array of Transaction (to, value, data) instead of targetcontract and function name
// If array length is one (given executionMethod = execute or executeFromExecutor) then make executionCallData for singletx
// handle preparing calldata for executeUserOp differently as it requires different parameters
// should be able to provide execution type (default or try)
// call type is understood from Transaction array above
// prepare mode accordingly
// think about name

export async function generateUseropCallData({
  executionMethod,
  targetContract,
  functionName,
  args = [],
  value = 0,
  mode = ethers.concat([
    CALLTYPE_SINGLE,
    EXECTYPE_DEFAULT,
    MODE_DEFAULT,
    UNUSED,
    MODE_PAYLOAD,
  ]),
}): Promise<string> {
  const AccountExecution = await ethers.getContractFactory("Nexus");

  const targetAddress = await targetContract.getAddress();
  // Encode the target function call data
  const functionCallData = targetContract.interface.encodeFunctionData(
    functionName,
    args,
  );

  // Encode the execution calldata
  let executionCalldata;
  switch (executionMethod) {
    case ExecutionMethod.Execute:
      // in case of EncodeSingle : abi.encodePacked(target, value, callData);
      // in case of encodeBatch:  abi.encode(executions);
      executionCalldata = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [targetAddress, value, functionCallData],
      );
      break;
    case ExecutionMethod.ExecuteFromExecutor:
      // in case of EncodeSingle : abi.encodePacked(target, value, callData);
      // in case of EncodeBatch:  abi.encode(executions);
      executionCalldata = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [targetAddress, value, functionCallData],
      );
      break;
    default:
      throw new Error("Invalid execution method type");
  }

  // Determine the method name based on the execution method
  // Can use switch case again
  let methodName;
  let executeCallData;
  if (executionMethod === ExecutionMethod.Execute) {
    methodName = "execute";
    executeCallData = AccountExecution.interface.encodeFunctionData(
      methodName,
      [mode, executionCalldata],
    );
  } else if (executionMethod === ExecutionMethod.ExecuteFromExecutor) {
    methodName = "executeFromExecutor";
    executeCallData = AccountExecution.interface.encodeFunctionData(
      methodName,
      [mode, executionCalldata],
    );
  }
  return executeCallData;
}

// Utility function to listen for UserOperationRevertReason events
export async function listenForRevertReasons(entryPointAddress: string) {
  const entryPoint = await ethers.getContractAt(
    "EntryPoint",
    entryPointAddress,
  );
  console.log("Listening for UserOperationRevertReason events...");

  entryPoint.on(
    entryPoint.getEvent("UserOperationRevertReason"),
    (userOpHash, sender, nonce, revertReason) => {
      const reason = ethers.toUtf8String(revertReason);
      console.log(`Revert Reason:
      User Operation Hash: ${userOpHash}
      Sender: ${sender}
      Nonce: ${nonce}
      Revert Reason: ${reason}`);
    },
  );
}

export function findEventInLogs(
  logs: any[],
  eventName: string,
): string | Error {
  for (let index = 0; index < logs.length; index++) {
    const fragmentName = logs[index].fragment.name;
    if (fragmentName === eventName) {
      return fragmentName;
    }
  }
  throw new Error("No event found with the given name");
}

export async function generateCallDataForExecuteUserop() {}

export async function getNonce(
  entryPoint: EntryPoint,
  accountAddress: AddressLike,
  validationMode: BytesLike,
  validatorModuleAddress: AddressLike,
) :Promise<bigint> {
  const vm = validatorModuleAddress.toString();
  const key = concat(["0x000000", validationMode, vm]);
  return await entryPoint.getNonce(accountAddress, key);
}

export const getAccountDomainStructFields = async (
  provider: Provider,
  accountAddress: string
) => {
  const accountInterface = new ethers.Interface([
    "function eip712Domain() public view returns (bytes1 fields, string memory name, string memory version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] memory extensions)"
  ]);

  const contract = new ethers.Contract(accountAddress, accountInterface, provider);

  const accountDomainStructFields = await contract.eip712Domain();

  const [fields, name, version, chainId, verifyingContract, salt, extensions] = accountDomainStructFields;

  const abiCoder = new ethers.AbiCoder();
  
  return abiCoder.encode(
    ["bytes1", "bytes32", "string", "uint256", "address", "bytes32", "bytes32"],
    [fields, keccak256(toBytes(name)), keccak256(toBytes(version)), chainId, verifyingContract, salt, keccak256(encodePacked(['uint256[]'],[extensions]))]
  );
};

// More functions to be added
// 1. simulateValidation (using EntryPointSimulations)
// 2. simulareHandleOps
