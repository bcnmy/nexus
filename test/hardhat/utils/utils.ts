import { artifacts, ethers } from "hardhat";

// Conversion to Bytes32
export const toBytes32 = (text: string): string => {
  return ethers.encodeBytes32String(text);
};

// Conversion from Bytes32
export const fromBytes32 = (bytes32: string): string => {
  return ethers.decodeBytes32String(bytes32);
};

// Convert to 18 decimals
export const to18Decimals = (value: number | string): bigint => {
  return ethers.parseUnits(value.toString(), 18);
};

// Convert from 18 decimals
export const from18Decimals = (value: bigint): string => {
  return ethers.formatUnits(value, 18);
};

export function buildUserOp({
  sender,
  nonce,
  initCode = "",
  callData = "",
  callGasLimit,
  executionGasLimit, // For the execution of callData
  verificationGasLimit, // For the validateUserOp
  preVerificationGas,
  maxFeePerGas,
  maxPriorityFeePerGas,
  paymaster = ethers.ZeroAddress,
  paymasterData = "0x",
  signature = "0x",
}: {
  sender: string;
  nonce: number;
  initCode?: string;
  callData?: string;
  callGasLimit: number;
  executionGasLimit: number; // For the execution of callData
  verificationGasLimit: number; // For the validateUserOp
  preVerificationGas: number;
  maxFeePerGas: number;
  maxPriorityFeePerGas: number;
  paymaster?: string;
  paymasterData?: string;
  signature?: string;
}) {
  // Ensure maxFeePerGas and maxPriorityFeePerGas are provided in wei
  const gasFees = ethers.solidityPacked(
    ["uint128", "uint128"],
    [maxFeePerGas, maxPriorityFeePerGas],
  );

  // Pack accountGasLimits as bytes32 combining callGasLimit and verificationGasLimit
  const accountGasLimits = ethers.solidityPacked(
    ["uint128", "uint128"],
    [executionGasLimit, verificationGasLimit],
  );

  // Combine paymaster address and additional data into paymasterAndData
  const paymasterAndData = ethers.AbiCoder.defaultAbiCoder().encode(
    ["address", "bytes"],
    [paymaster, paymasterData],
  );

  // Construct the PackedUserOperation object
  const packedUserOp = {
    sender,
    nonce,
    initCode,
    callData,
    accountGasLimits: ethers.hexlify(accountGasLimits),
    preVerificationGas,
    gasFees: ethers.hexlify(gasFees),
    paymasterAndData,
    signature,
  };

  return packedUserOp;
}
