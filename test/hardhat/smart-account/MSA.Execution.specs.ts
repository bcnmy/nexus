import { ethers } from "hardhat";
import { expect } from "chai";

import { AddressLike, Signer } from "ethers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ExecutionMethod, ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import { encodeData } from "../utils/encoding";
import {
  generateUseropCallData,
  buildPackedUserOp,
  signAndPackUserOp,
} from "../utils/operationHelpers";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
} from "../utils/erc7579Utils";

describe("SmartAccount Execution and Validation", () => {
  let factory: AccountFactory;
  let smartAccount: SmartAccount;
  let entryPoint: EntryPoint;
  let module: MockValidator;
  let counter: Counter;
  let accounts: Signer[];
  let addresses: string[] | AddressLike[];
  let factoryAddress: AddressLike;
  let entryPointAddress: AddressLike;
  let smartAccountAddress: AddressLike;
  let moduleAddress: AddressLike;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let bundler: Signer;
  let bundlerAddress: AddressLike;
  let counterAddress: AddressLike;
  let userSA: SmartAccount;

  beforeEach(async () => {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccountImplementation;
    module = setup.mockValidator;
    factory = setup.msaFactory;
    accounts = setup.accounts;
    addresses = setup.addresses;
    counter = setup.counter;
    owner = setup.accountOwner;
    userSA = setup.deployedMSA;
    smartAccountAddress = setup.deployedMSAAddress;

    entryPointAddress = await entryPoint.getAddress();

    moduleAddress = await module.getAddress();
    factoryAddress = await factory.getAddress();
    counterAddress = await counter.getAddress();
    ownerAddress = await owner.getAddress();

    bundler = ethers.Wallet.createRandom();
    bundlerAddress = await bundler.getAddress();
  });

  // Review: Debug
  describe("SmartAccount Transaction Execution", () => {
    it("Should execute a single transaction through the EntryPoint using execute", async () => {
      // Generate calldata for executing the 'incrementNumber' function on the counter contract.
      // TODO
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      // Build the userOp with the generated callData.
      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(moduleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await owner.signMessage(ethers.getBytes(userOpHash));

      userOp.signature = signature;

      // Assert the counter's state (testing contract) before execution to ensure it's at its initial state.
      expect(await counter.getNumber()).to.equal(0);

      // Execute the signed userOp through the EntryPoint contract and verify the counter's state post-execution.

      await entryPoint.handleOps([userOp], bundlerAddress);

      expect(await counter.getNumber()).to.equal(1);
    });

    it("Should handle transactions via the ExecuteFromExecutor method correctly", async () => {});

    it("Should process executeUserOp method correctly", async () => {});
  });
});
