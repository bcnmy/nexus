import { NumberLike } from "@nomicfoundation/hardhat-network-helpers/dist/src/types";
import {
  AddressLike,
  BigNumberish,
  BytesLike,
  HDNodeWallet,
  Signer,
} from "ethers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockToken,
  MockValidator,
  K1Validator,
  SmartAccount,
  MockExecutor,
  IValidator,
  IExecutor,
  MockHook,
  MockHandler,
} from "../../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

export interface DeploymentFixture {
  entryPoint: EntryPoint;
  smartAccountImplementation: SmartAccount;
  msaFactory: AccountFactory;
  mockValidator: MockValidator;
  ecdsaValidator: K1Validator;
  counter: Counter;
  mockToken: MockToken;
  accounts: Signer[];
  addresses: string[];
}

export interface DeploymentFixtureWithSA {
  entryPoint: EntryPoint;
  smartAccountImplementation: SmartAccount;
  deployedMSA: SmartAccount;
  aliceDeployedMSA: SmartAccount
  deployedMSAAddress: AddressLike;
  accountOwner: HardhatEthersSigner;
  aliceAccountOwner: HardhatEthersSigner;
  msaFactory: AccountFactory;
  deployer: Signer;
  mockValidator: MockValidator;
  mockExecutor: MockExecutor;
  mockHook: MockHook;
  mockFallbackHandler: MockHandler;
  anotherExecutorModule: MockExecutor;
  ecdsaValidator: K1Validator;
  counter: Counter;
  mockToken: MockToken;
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

export type InstallModuleParams = {
  deployedMSA: SmartAccount,
  entryPoint: EntryPoint,
  moduleToInstall: any,
  moduleType: ModuleType,
  validatorModule: MockValidator | K1Validator,
  accountOwner: Signer,
  bundler: Signer
}