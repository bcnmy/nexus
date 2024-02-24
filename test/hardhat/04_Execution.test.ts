import { ethers } from "hardhat";
import { expect } from "chai";

import { AddressLike, Signer } from "ethers";
import {
  AccountFactory,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ExecutionMethod, ModuleType } from "./utils/types";
import { deploySmartAccountWithEntrypointFixture } from "./utils/deployment";
import { encodeData } from "./utils/encoding";
import {
  generateExecutionCallData,
  buildSignedUserOp,
  buildPackedUserOp,
} from "./utils/operationHelpers";

describe("SmartAccount Execution and Validation", () => {
  let setup, bundler;
  let factory, smartAccount, entryPoint, module, counter, owner;
  let factoryAddress,
    entryPointAddress,
    smartAccountAddress,
    moduleAddress,
    counterAddress,
    ownerAddress,
    bundlerAddress;

  beforeEach(async () => {
    setup = await loadFixture(deploySmartAccountWithEntrypointFixture);
    ({ factory, smartAccount, entryPoint, module, counter, owner } = setup);

    factoryAddress = await factory.getAddress();
    entryPointAddress = await entryPoint.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    moduleAddress = await module.getAddress();
    counterAddress = await counter.getAddress();
    ownerAddress = await owner.getAddress();
    bundler = ethers.Wallet.createRandom();
    bundlerAddress = await bundler.getAddress();
  });

  describe("SmartAccount Transaction Execution", () => {
    it("Should execute a single transaction through the EntryPoint using execute", async () => {
      // Generate calldata for executing the 'incrementNumber' function on the counter contract.
      const callData = await generateExecutionCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
        mode: "TEST_MODE",
      });

      // Sign the operation with the owner's signature to authorize the transaction.
      const signedPackedUserOps = await buildSignedUserOp(
        {
          sender: smartAccountAddress,
          callData,
        },
        owner,
        setup,
      );

      // Assert the counter's state (testing contract) before execution to ensure it's at its initial state.
      expect(await counter.getNumber()).to.equal(0);

      // Execute the signed userOp through the EntryPoint contract and verify the counter's state post-execution.
      await entryPoint.handleOps([signedPackedUserOps], bundlerAddress);

      expect(await counter.getNumber()).to.equal(1);
    });

    it("Should handle transactions via the ExecuteFromExecutor method correctly", async () => {
      // Generate calldata for 'executeFromExecutor' method, targeting the 'incrementNumber' function of the counter contract.
      const callData = await generateExecutionCallData({
        executionMethod: ExecutionMethod.ExecuteFromExecutor,
        targetContract: counter,
        functionName: "incrementNumber",
        mode: "TEST_MODE",
      });

      const signedPackedUserOps = await buildSignedUserOp(
        {
          sender: smartAccountAddress,
          callData,
        },
        owner,
        setup,
      );

      expect(await counter.getNumber()).to.equal(0);

      // Execute the transaction using a different execution method but expecting the same outcome.
      await entryPoint.handleOps([signedPackedUserOps], bundlerAddress);
      expect(await counter.getNumber()).to.equal(1);
    });

    it("Should process executeUserOp method correctly", async () => {
      // Prepare call data for the 'executeUserOp' method, involving direct interaction with userOps
      const counterFuncData =
        counter.interface.encodeFunctionData("incrementNumber");

      // Note: encodeData is used to manually encode the transaction data for 'executeUserOp'.
      const executionCalldata = encodeData(
        ["address", "uint256", "bytes"],
        [counterAddress, ModuleType.Validation, counterFuncData],
      );

      // Fetch the nonce for the userOp, to avoid replay attacks.
      const nonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(moduleAddress as string, 24),
      );

      // Build the UserOp with the execution calldata, ready for signing and execution.
      const packedUserOp = await buildPackedUserOp({
        sender: smartAccountAddress,
        callData: executionCalldata as any,
        nonce,
      });

      const userOpHash = await entryPoint.getUserOpHash(packedUserOp);

      // Sign the userOp hash with owner's signature
      const signature = await owner.signMessage(ethers.getBytes(userOpHash));

      packedUserOp.signature = signature;

      // Generate the call data specifically for the 'executeUserOp' method.
      const callData = await generateExecutionCallData(
        {
          executionMethod: ExecutionMethod.ExecuteUserOp,
          targetContract: counter,
          functionName: "incrementNumber",
          mode: "TEST_MODE",
        },
        packedUserOp as any,
        userOpHash,
      );

      // Assign the generated call data to the packedUserOp

      packedUserOp.callData = callData;

      // Re-sign the userOp with the updated hash due to calldata assignment
      const executUserOpHash = await entryPoint.getUserOpHash(packedUserOp);

      packedUserOp.signature = await owner.signMessage(
        ethers.getBytes(executUserOpHash),
      );

      await entryPoint.handleOps([packedUserOp], bundlerAddress);
      expect(await counter.getNumber()).to.equal(0);
    });
  });
});
