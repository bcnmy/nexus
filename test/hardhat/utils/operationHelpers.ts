import { ethers } from "hardhat";
import { toGwei } from "./encoding";
import { ExecutionMethod, PackedUserOperation, UserOperation } from "./types";
import {
  Signer,
  AddressLike,
  BytesLike,
  BigNumberish,
  toBeHex,
  concat,
  getBytes,
  getAddress,
  hexlify,
  zeroPadValue,
} from "ethers";
import { EntryPoint, Nexus } from "../../../typechain-types";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
} from "./erc7579Utils";

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

const abiCoder = new ethers.AbiCoder();
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
  batchId: string = "0x000000",
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
    validatorAddress,
    batchId,
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

/**
 * Converts a number to a 3-byte hexadecimal string.
 * @param num The number to convert (must be between 0 and 16777215 inclusive)
 * @returns A 3-byte hexadecimal string representation of the number
 * @throws Error if the number is out of range
 */
export function numberTo3Bytes(num: number): string {
  if (num < 0 || num > 0xffffff) {
    throw new Error(
      "Number out of range. Must be between 0 and 16777215 inclusive.",
    );
  }
  return "0x" + num.toString(16).padStart(6, "0");
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
  batchId: string = "0x000000",
): Promise<PackedUserOperation> {
  const nonce = await getNonce(
    entryPoint,
    accountAddress,
    validationMode,
    validatorAddress,
    batchId,
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
 * Generates the full initialization code for deploying a smart account via NexusAccountFactory.
 * @param initData - The initialization data for the smart account (encoded bootstrap call).
 * @param salt - The salt for CREATE2 deployment.
 * @param factoryAddress - The address of the NexusAccountFactory contract.
 * @returns The full initialization code as a hex string.
 */
export async function getInitCode(
  initData: BytesLike,
  salt: BytesLike,
  factoryAddress: AddressLike,
): Promise<string> {
  const NexusAccountFactory = await ethers.getContractFactory(
    "NexusAccountFactory"
  );

  // Encode the createAccount function call with the provided parameters
  const factoryDeploymentData = NexusAccountFactory.interface
    .encodeFunctionData("createAccount", [
      initData,
      salt,
    ])
    .slice(2);

  return factoryAddress + factoryDeploymentData;
}

// Note: could be a method getAccountAddressAndInitCode

/**
 * Calculates the CREATE2 address for a smart account deployment using NexusAccountFactory.
 * @param {BytesLike} initData - The initialization data for the smart account.
 * @param {BytesLike} salt - The salt for CREATE2 deployment.
 * @param {AddressLike} factoryAddress - The address of the NexusAccountFactory contract.
 * @param {Object} setup - The setup object containing deployed contracts and addresses.
 * @returns {Promise<string>} The calculated CREATE2 address.
 */
// Note: could add off-chain way later using Create2 utils
export async function getAccountAddress(
  initData: BytesLike,
  salt: BytesLike,
  factoryAddress: AddressLike,
  setup: { accountFactory: any },
): Promise<string> {
  setup.accountFactory = setup.accountFactory.attach(factoryAddress);

  const counterFactualAddress =
    await setup.accountFactory.computeAccountAddress(
      initData,
      salt,
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

// Helper to mimic the `makeNonceKey` function in Solidity
function makeNonceKey(
  vMode: BytesLike,
  validator: AddressLike,
  batchId: BytesLike,
): string {
  // Convert the validator address to a Uint8Array
  const validatorBytes = getBytes(getAddress(validator.toString()));

  // Prepare the validation mode as a 1-byte Uint8Array
  const validationModeBytes = Uint8Array.from([Number(vMode)]);

  // Convert the batchId to a Uint8Array (assuming it's 3 bytes)
  const batchIdBytes = getBytes(batchId);

  // Create a 24-byte array for the 192-bit key
  const keyBytes = new Uint8Array(24);

  // Set the batchId in the most significant 3 bytes (positions 0, 1, and 2)
  keyBytes.set(batchIdBytes, 0);

  // Set the validation mode at the 4th byte (position 3)
  keyBytes.set(validationModeBytes, 3);

  // Set the validator address starting from the 5th byte (position 4)
  keyBytes.set(validatorBytes, 4);

  // Return the key as a hex string
  return hexlify(keyBytes);
}

// Adjusted getNonce function
export async function getNonce(
  entryPoint: EntryPoint,
  accountAddress: AddressLike,
  validationMode: BytesLike,
  validatorModuleAddress: AddressLike,
  batchId: BytesLike = "0x000000",
): Promise<bigint> {
  const key = makeNonceKey(validationMode, validatorModuleAddress, batchId);
  return await entryPoint.getNonce(accountAddress, key);
}
export async function getAccountDomainStructFields(
  account: Nexus,
): Promise<string> {
  const [fields, name, version, chainId, verifyingContract, salt, extensions] =
    await account.eip712Domain();
  return ethers.AbiCoder.defaultAbiCoder().encode(
    ["bytes32", "bytes32", "uint256", "address", "bytes32"],
    [
      ethers.keccak256(ethers.toUtf8Bytes(name)), // matches Solidity
      ethers.keccak256(ethers.toUtf8Bytes(version)), // matches Solidity
      chainId,
      verifyingContract,
      salt,
    ],
  );
}

// Helper to impersonate an account
export async function impersonateAccount(address: string) {
  await ethers.provider.send("hardhat_impersonateAccount", [address]);
  return ethers.getSigner(address);
}

// Helper to stop impersonating an account
export async function stopImpersonateAccount(address: string) {
  await ethers.provider.send("hardhat_stopImpersonatingAccount", [address]);
}
