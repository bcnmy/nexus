import { artifacts, ethers } from "hardhat";
import { PackedUserOperation, UserOperation } from "./types";
import { Signer } from "ethers";
import { sign } from "crypto";

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

export function toGwei(amount: number | string | bigint): string | bigint {
  return ethers.parseUnits(amount.toString(), "gwei");
}

export function buildPackedUserOp(userOp: UserOperation): PackedUserOperation {
  const {
    sender,
    nonce,
    initCode = "0x",
    callData = "0x",
    callGasLimit = 1_000_000,
    verificationGasLimit = 1_000_000,
    preVerificationGas = 1_500_000,
    maxFeePerGas = toGwei(10),
    maxPriorityFeePerGas = toGwei(5),
    paymaster = ethers.ZeroAddress,
    paymasterData = "0x",
    signature = "0x",
  } = userOp;

  // Pack gasFees and accountGasLimits as bytes32
  const gasFees = ethers.solidityPacked(
    ["uint128", "uint128"],
    [maxPriorityFeePerGas, maxFeePerGas],
  );

  // Pack accountGasLimits as bytes32 combining callGasLimit and verificationGasLimit
  const accountGasLimits = ethers.solidityPacked(
    ["uint128", "uint128"],
    [callGasLimit, verificationGasLimit],
  );

  const paymasterAndData = ethers.AbiCoder.defaultAbiCoder().encode(
    ["address", "bytes"],
    [paymaster, paymasterData],
  );

  // Construct the PackedUserOperation object
  const packedUserOp: PackedUserOperation = {
    sender,
    nonce: nonce,
    initCode,
    callData,
    accountGasLimits: accountGasLimits,
    preVerificationGas: preVerificationGas,
    gasFees: ethers.hexlify(gasFees),
    paymasterAndData,
    signature,
  };

  return packedUserOp;
}