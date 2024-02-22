export interface UserOperation {
  sender: string;
  nonce: number | string | bigint;
  initCode?: string;
  callData?: string;
  callGasLimit?: number | string | bigint;
  verificationGasLimit?: number | string | bigint;
  preVerificationGas?: number | string | bigint;
  maxFeePerGas?: number | string | bigint;
  maxPriorityFeePerGas?: number | string | bigint;
  paymaster?: string;
  paymasterData?: string;
  signature?: string;
}

export interface PackedUserOperation {
  sender: string;
  nonce: number | string | bigint;
  initCode: string;
  callData: string;
  accountGasLimits: string | number | bigint;
  preVerificationGas: string | number | bigint;
  gasFees: string | number | bigint;
  paymasterAndData: string;
  signature: string;
}
