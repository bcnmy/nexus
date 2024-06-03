import {
  AddressLike,
  BigNumberish,
  BytesLike,
  ParamType,
  Signer,
} from "ethers";
import {
  K1ValidatorFactory,
  Counter,
  EntryPoint,
  MockToken,
  MockValidator,
  K1Validator,
  Nexus,
  MockExecutor,
  MockHook,
  MockHandler,
  Stakeable,
  BiconomyMetaFactory,
  NexusAccountFactory,
  Bootstrap,
  BootstrapLib,
  ModuleWhitelistFactory,
} from "../../../typechain-types";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

export interface DeploymentFixture {
  entryPoint: EntryPoint;
  smartAccountImplementation: Nexus;
  nexusFactory: K1ValidatorFactory;
  mockValidator: MockValidator;
  ecdsaValidator: K1Validator;
  counter: Counter;
  mockToken: MockToken;
  accounts: Signer[];
  addresses: string[];
}

export interface DeploymentFixtureWithSA {
  entryPoint: EntryPoint;
  smartAccountImplementation: Nexus;
  deployedNexus: Nexus;
  aliceDeployedNexus: Nexus;
  deployedNexusAddress: AddressLike;
  accountOwner: HardhatEthersSigner;
  aliceAccountOwner: HardhatEthersSigner;
  nexusK1Factory: K1ValidatorFactory;
  deployer: Signer;
  mockValidator: MockValidator;
  mockExecutor: MockExecutor;
  mockHook: MockHook;
  mockHook2: MockHook;
  mockFallbackHandler: MockHandler;
  ecdsaValidator: K1Validator;
  counter: Counter;
  mockToken: MockToken;
  accounts: Signer[];
  addresses: string[];
  stakeable: Stakeable;
  metaFactory: BiconomyMetaFactory;
  nexusFactory: NexusAccountFactory;
  bootstrap: Bootstrap;
  BootstrapLib: BootstrapLib;
  moduleWhitelistFactory: ModuleWhitelistFactory;
}

// TODO: check for need of making these optional
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

export type ModuleParams = {
  deployedNexus: Nexus;
  entryPoint: EntryPoint;
  module: any;
  moduleType: ModuleType | number;
  validatorModule: MockValidator | K1Validator;
  accountOwner: Signer;
  bundler: Signer;
  data?: BytesLike;
};

export const Executions = ParamType.from({
  type: "tuple(address,uint256,bytes)[]",
  baseType: "tuple",
  name: "executions",
  arrayLength: null,
  components: [
    { name: "target", type: "address" },
    { name: "value", type: "uint256" },
    { name: "callData", type: "bytes" },
  ],
});
