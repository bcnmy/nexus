import { NumberLike } from "@nomicfoundation/hardhat-network-helpers/dist/src/types";
import { AddressLike, BigNumberish, BytesLike, Signer } from "ethers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";

export interface DeploymentFixture {
  entryPoint: EntryPoint;
  smartAccount: SmartAccount;
  factory: AccountFactory;
  module: MockValidator;
  counter: Counter;
  accounts: Signer[];
  addresses: string[];
}

// Todo
// Review: check for need of making these optional
export interface UserOperation {
  sender: AddressLike; // Or string
  nonce?: BigNumberish;
  initCode?: BytesLike;
  callData?: BytesLike;
  callGasLimit?: BigNumberish;
  verificationGasLimit?: BigNumberish;
  preVerificationGas?: BigNumberish;
  maxFeePerGas?: BigNumberish;
  maxPriorityFeePerGas?: BigNumberish;
  paymaster?: AddressLike; // Or string
  paymasterVerificationGasLimit?: BigNumberish;
  paymasterPostOpGasLimit?: BigNumberish;
  paymasterData?: BytesLike;
  signature?: BytesLike;
}

export interface PackedUserOperation {
  sender: AddressLike; // Or string
  nonce: BigNumberish;
  initCode: BytesLike;
  callData: BytesLike;
  accountGasLimits: BytesLike;
  preVerificationGas: BigNumberish;
  gasFees: BytesLike;
  paymasterAndData: BytesLike;
  signature: BytesLike;
}

export enum ExecutionMethod {
  Execute,
  ExecuteFromExecutor,
  ExecuteUserOp,
}

export enum ModuleType {
  Validation = 1,
  Execution = 2,
  Fallback = 3,
  Hooks = 4,
}
