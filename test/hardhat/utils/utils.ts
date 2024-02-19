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
