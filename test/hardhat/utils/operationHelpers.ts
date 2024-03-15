import { ethers } from "hardhat";
import { encodeData, toGwei } from "./encoding";
import {
  ExecutionMethod,
  ModuleType,
  PackedUserOperation,
  UserOperation,
} from "./types";
import {
  Signer,
  AddressLike,
  BytesLike,
  BigNumberish,
  hexlify,
  toBeHex,
} from "ethers";
import { EntryPoint } from "../../../typechain-types";
import { Hexable } from "@ethersproject/bytes";

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
export async function buildSignedUserOp(
  userOp: UserOperation,
  signer: Signer,
  setup: { entryPoint: any; module: any },
  deposit?: string,
): Promise<PackedUserOperation> {
  if (!setup.entryPoint || !setup.module) {
    throw new Error("Setup object is missing required properties.");
  }
  if (!signer) {
    throw new Error("Signer must be provided.");
  }

  const moduleAddress = await setup.module.getAddress();
  const nonce = await setup.entryPoint.getNonce(
    userOp.sender,
    ethers.zeroPadBytes(moduleAddress, 24),
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

export async function signUserOperation(
  accountAddress: AddressLike,
  initCode: BytesLike,
  entryPoint: EntryPoint,
  moduleAddress: AddressLike,
  owner: Signer,
): Promise<PackedUserOperation> {
  const nonce = await entryPoint.getNonce(
    accountAddress,
    ethers.zeroPadBytes(moduleAddress.toString(), 24),
  );
  const userOp = buildPackedUserOp({ sender: accountAddress, nonce, initCode });
  const userOpHash = await entryPoint.getUserOpHash(userOp);
  userOp.signature = await owner.signMessage(ethers.getBytes(userOpHash));
  return userOp;
}

/**
 * Generates the full initialization code for deploying a smart account.
 * @param factoryAddress - The address of the AccountFactory contract.
 * @param moduleAddress - The address of the module to be installed in the smart account.
 * @param ownerAddress - The address of the owner of the new smart account.
 * @param moduleType - The type of module to install, defaulting to "1".
 * @returns The full initialization code as a hex string.
 */
export async function generateFullInitCode(
  ownerAddress: AddressLike,
  factoryAddress: AddressLike,
  moduleAddress: AddressLike,
  moduleType: ModuleType = ModuleType.Validation,
  saDeploymentIndex: number = 0,
): Promise<string> {
  const AccountFactory = await ethers.getContractFactory("AccountFactory");
  const moduleInitData = ethers.solidityPacked(["address"], [ownerAddress]);

  // Encode the createAccount function call with the provided parameters
  const initCode = AccountFactory.interface
    .encodeFunctionData("createAccount", [
      moduleAddress,
      moduleInitData,
      saDeploymentIndex,
    ])
    .slice(2);

  return factoryAddress + initCode;
}

// REVIEW

/**
 * Calculates the CREATE2 address for a smart account deployment.
 * @param {AddressLike} signerAddress - The address of the signer (owner of the new smart account).
 * @param {AddressLike} factoryAddress - The address of the AccountFactory contract.
 * @param {AddressLike} moduleAddress - The address of the module to be installed in the smart account.
 * @param {number | string} moduleType - The type of module to install.
 * @returns {Promise<string>} The calculated CREATE2 address.
 */
export async function getAccountAddress(
  signerAddress: AddressLike,
  factoryAddress: AddressLike,
  moduleAddress: AddressLike,
  moduleType: ModuleType = ModuleType.Validation,
  saDeploymentIndex: number = 0,
): Promise<string> {
  // Ensure SmartAccount bytecode is fetched dynamically in case of contract upgrades
  const SmartAccount = await ethers.getContractFactory("SmartAccount");
  const smartAccountBytecode = SmartAccount.bytecode;

  // Module initialization data, encoded
  const moduleInitData = ethers.solidityPacked(["address"], [signerAddress]);

  // Salt for CREATE2, based on module address, type, and initialization data
  const salt = ethers.solidityPackedKeccak256(
    ["address", "bytes", "uint256"],
    [moduleAddress, moduleInitData, saDeploymentIndex],
  );

  // Calculate CREATE2 address using ethers utility function
  const create2Address = ethers.getCreate2Address(
    factoryAddress.toString(),
    salt,
    ethers.keccak256(smartAccountBytecode),
  );

  return create2Address;
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

// TODO: need to take an argument for CallType and ExecType as well. if it's single or batch / revert or try
// Whole method needs to be refactored

export async function generateExecutionCallData(
  { executionMethod, targetContract, functionName, args = [], mode, value = 0 },
  packedUserOp = "0x",
  userOpHash = "0x",
): Promise<string> {
  // Fetch the signer from the contract object
  const AccountExecution = await ethers.getContractFactory("SmartAccount");

  const targetAddress = await targetContract.getAddress();
  // Encode the target function call data
  const functionCallData = targetContract.interface.encodeFunctionData(
    functionName,
    args,
  );
  const modeHash = ethers.keccak256(ethers.toUtf8Bytes(mode));

  // Encode the execution calldata
  let executionCalldata;
  switch (executionMethod) {
    case ExecutionMethod.Execute:
    case ExecutionMethod.ExecuteFromExecutor:
      // in case of EncodeSingle : abi.encodePacked(target, value, callData);
      // in case of encodeBatch:  abi.encode(executions);
      executionCalldata = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "uint256", "bytes"],
        [targetAddress, value, functionCallData],
      );
      break;
    case ExecutionMethod.ExecuteUserOp:
      executionCalldata = ethers.AbiCoder.defaultAbiCoder().encode(
        ["bytes32", "address", "uint256", "bytes"],
        [modeHash, targetAddress, value, functionCallData],
      );
      break;
    default:
      throw new Error("Invalid execution method type");
  }

  // Determine the method name based on the execution method
  let methodName;
  let executeCallData;
  if (executionMethod === ExecutionMethod.Execute) {
    methodName = "execute";

    executeCallData = AccountExecution.interface.encodeFunctionData(
      methodName,
      [modeHash, executionCalldata],
    );
  } else if (executionMethod === ExecutionMethod.ExecuteFromExecutor) {
    methodName = "executeFromExecutor";
    executeCallData = AccountExecution.interface.encodeFunctionData(
      methodName,
      [modeHash, executionCalldata],
    );
  } else if (executionMethod === ExecutionMethod.ExecuteUserOp) {
    methodName = "executeUserOp";
    executeCallData = AccountExecution.interface.encodeFunctionData(
      methodName,
      [packedUserOp, userOpHash],
    );
  }
  return executeCallData;
}
