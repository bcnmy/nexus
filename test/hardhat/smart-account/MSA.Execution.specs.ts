import { ExecutionMethod } from './../utils/types';
import { ethers } from "hardhat";
import { expect } from "chai";

import { Signer } from "ethers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockExecutor,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import {
  generateUseropCallData,
  buildPackedUserOp,
  listenForRevertReasons,
} from "../utils/operationHelpers";

describe("SmartAccount Execution and Validation", () => {
    let factory: AccountFactory;
    let entryPoint: EntryPoint;
    let bundler: Signer;
    let validatorModule: MockValidator;
    let executorModule: MockExecutor;
    let counter: Counter;
    let smartAccount: SmartAccount;
    let smartAccountOwner: Signer;

    let factoryAddress: string;
    let entryPointAddress: string;
    let bundlerAddress: string;
    let validatorModuleAddress: string;
    let executorModuleAddress: string;
    let counterAddress: string;
    let smartAccountAddress: string;
    let smartAccountOwnerAddress: string;

  beforeEach(async () => {

    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    factory = setup.msaFactory;
    bundler = ethers.Wallet.createRandom();
    validatorModule = setup.mockValidator;
    executorModule = setup.mockExecutor;
    smartAccountOwner = setup.accountOwner;
    smartAccount = setup.deployedMSA;
    counter = setup.counter;

    factoryAddress = await factory.getAddress();
    entryPointAddress = await entryPoint.getAddress();
    bundlerAddress = await bundler.getAddress();
    validatorModuleAddress = await validatorModule.getAddress();
    executorModuleAddress = await executorModule.getAddress();
    counterAddress = await counter.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    smartAccountOwnerAddress = await smartAccountOwner.getAddress();

    // First install the executor module on the smart account
    const isOwner = await validatorModule.isOwner(smartAccountAddress, smartAccountOwnerAddress);
                
    expect(isOwner).to.be.true;

    const installModuleData = await generateUseropCallData({
      executionMethod: ExecutionMethod.Execute,
      targetContract: smartAccount,
      functionName: "installModule",
      args: [ModuleType.Execution, executorModuleAddress, ethers.hexlify("0x")],
    });

    const userOp = buildPackedUserOp({
      sender: smartAccountAddress,
      callData: installModuleData,
    });

    const nonce = await entryPoint.getNonce(
      userOp.sender,
      ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
    );
    userOp.nonce = nonce; 

    const userOpHash = await entryPoint.getUserOpHash(userOp);
    const signature = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));
    userOp.signature = signature;

    await entryPoint.handleOps([userOp], bundlerAddress);

    const isInstalled = await smartAccount.isModuleInstalled(
      ModuleType.Execution,
      executorModuleAddress,
      ethers.hexlify("0x"),
    )

    expect(isInstalled).to.be.true;

  });

  // Review: Debug
  describe("SmartAccount Transaction Execution", () => {
    it("Should execute a single transaction through the EntryPoint using execute", async () => {
      const isOwner = await validatorModule.isOwner(smartAccountAddress, smartAccountOwnerAddress);
      expect(isOwner).to.be.true;
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
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce; 

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));

      userOp.signature = signature;

      // Assert the counter's state (testing contract) before execution to ensure it's at its initial state.
      expect(await counter.getNumber()).to.equal(0);
      // Execute the signed userOp through the EntryPoint contract and verify the counter's state post-execution.
      
      await entryPoint.handleOps([userOp], bundlerAddress);

      expect(await counter.getNumber()).to.equal(1);
    });

    it("Should execute a transaction through the executor module directly", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      const numberBefore = await counter.getNumber();
      await executorModule.executeViaAccount(smartAccountAddress, counterAddress, 0n, incrementNumber);

      const numberAfter = await counter.getNumber();
      
      expect(numberAfter).to.be.greaterThan(numberBefore);
    });

    it("Should execute a transaction through the executor module by sending a user operation", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");
      
      const data = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "executeViaAccount", args: [smartAccountAddress, counterAddress, 0n, incrementNumber]});

      const incrementNumberUserOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: data,
      });

      const incrementNumberUserOpNonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      incrementNumberUserOp.nonce = incrementNumberUserOpNonce; 

      const incrementNumberUserOpHash = await entryPoint.getUserOpHash(incrementNumberUserOp);
      const incrementNumberUserOpSignature = await smartAccountOwner.signMessage(ethers.getBytes(incrementNumberUserOpHash));
      incrementNumberUserOp.signature = incrementNumberUserOpSignature;

      await listenForRevertReasons(entryPointAddress);
      console.log(incrementNumberUserOp, "user op");
      
      const numberBefore = await counter.getNumber();
      await entryPoint.handleOps([incrementNumberUserOp], bundlerAddress);
      const numberAfter = await counter.getNumber();
      
      expect(numberAfter).to.be.greaterThan(numberBefore);
    });
  });
});
