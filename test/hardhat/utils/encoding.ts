import { BigNumberish } from "ethers";
import { ethers } from "hardhat";

/**
 * Encodes data using the defaultAbiCoder from ethers.AbiCoder.
 * @param types The types of the values being encoded.
 * @param values The values to encode.
 * @returns The encoded data.
 */
export function encodeData(types: string[], values: any[]): string {
  return ethers.AbiCoder.defaultAbiCoder().encode(types, values);
}

/**
 * Converts a regular string to a bytes32 string.
 *
 * @param text The regular string to convert.
 * @returns The converted bytes32 string.
 */
export const toBytes32 = (text: string): string => {
  return ethers.encodeBytes32String(text);
};

/**
 * Converts a bytes32 string to a regular string.
 *
 * @param bytes32 The bytes32 string to convert.
 * @returns The converted regular string.
 */
export const fromBytes32 = (bytes32: string): string => {
  return ethers.decodeBytes32String(bytes32);
};

/**
 * Converts a numeric value to its equivalent in 18 decimal places.
 * @param value The numeric value to convert.
 * @returns The equivalent value in 18 decimal places as a bigint.
 */
export const to18 = (value: BigNumberish): bigint => {
  return ethers.parseUnits(value.toString(), 18);
};

/**
 * Converts a value from 18 decimal places to a string representation.
 *
 * @param value The value to convert.
 * @returns The string representation of the converted value.
 */
export const from18 = (value: bigint): string => {
  return ethers.formatUnits(value, 18);
};

/**
 * Converts the given amount to Gwei.
 * @param amount - The amount to convert.
 * @returns The converted amount in Gwei.
 */
export function toGwei(amount: BigNumberish): BigNumberish {
  return ethers.parseUnits(amount.toString(), "gwei");
}
