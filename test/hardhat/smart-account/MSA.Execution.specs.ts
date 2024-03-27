import { ExecutionMethod } from './../utils/types';
import { expect } from "chai";

import { ContractTransactionResponse, Signer } from "ethers";
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
} from "../utils/operationHelpers";
import { ethers } from 'hardhat';

describe("SmartAccount Execution and Validation", () => {
    let factory: AccountFactory;
    let entryPoint: EntryPoint;
    let bundler: Signer;
    let validatorModule: MockValidator;
    let executorModule: MockExecutor;
    let anotherExecutorModule: MockExecutor;
    let counter: Counter;
    let smartAccount: SmartAccount;
    let smartAccountOwner: Signer;
    let deployer: Signer;

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
    anotherExecutorModule = setup.anotherExecutorModule;
    smartAccountOwner = setup.accountOwner;
    smartAccount = setup.deployedMSA;
    counter = setup.counter;
    deployer = setup.deployer;

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

    it("Should execute a transaction via MockExecutor", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      const numberBefore = await counter.getNumber();
      await executorModule.executeViaAccount(smartAccountAddress, counterAddress, 0n, incrementNumber);

      const numberAfter = await counter.getNumber();
      
      expect(numberAfter).to.be.greaterThan(numberBefore);
    });

    it("Should do batch execution via MockExecutor", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      const execs = [{target: counterAddress, value: 0n, callData: incrementNumber}, {target: counterAddress, value: 0n, callData: incrementNumber}];
      const numberBefore = await counter.getNumber();
      await executorModule.execBatch(smartAccountAddress, execs);
      const numberAfter = await counter.getNumber();

      expect(numberAfter - numberBefore).to.be.equal(2);
    });

    it("Should do batch execution via MockExecutor", async () => {
      const execs = [];
      const results: ContractTransactionResponse = await executorModule.execBatch(smartAccountAddress, execs);
      
      expect(results.value).to.be.equal(0);
    });

  //   // Test executing an empty batch via executor
  //   function test_ExecuteEmptyBatchFromExecutor() public {
  //     Execution[] memory executions = new Execution[](0);
  //     bytes[] memory results = mockExecutor.execBatch(BOB_ACCOUNT, executions);
  //     assertEq(results.length, 0, "Results array should be empty");
  // }

    it("Should transfer value via MockExecutor", async () => {
      const randomAddress = ethers.Wallet.createRandom().address;
      await deployer.sendTransaction({to: smartAccountAddress, value: 1});
      
      await executorModule.executeViaAccount(smartAccountAddress, randomAddress, 1n, "0x");

      const balance = await deployer.provider.getBalance(randomAddress);
      expect(balance).to.be.equal(1);
    });

    it("Should execute a transaction through the executor module by using the entryPoint handleOps", async () => {
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

      const numberBefore = await counter.getNumber();
      await entryPoint.handleOps([incrementNumberUserOp], bundlerAddress);
      const numberAfter = await counter.getNumber();
      
      expect(numberAfter).to.be.greaterThan(numberBefore);
    });

    // Revert checks

    it("Should revert with InvalidModule custom error, through direct call to executor. Module not installed.", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      await expect(anotherExecutorModule.executeViaAccount(smartAccountAddress, counterAddress, 0n, incrementNumber)).to.be.revertedWithCustomError(smartAccount, "InvalidModule");
    });

    it("Should revert without a reason, through direct call to executor. Wrong smart account address given to executeViaAccount()", async () => {
      const randomAddress = ethers.Wallet.createRandom().address;
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      await expect(executorModule.executeViaAccount(randomAddress, counterAddress, 0n, incrementNumber)).to.be.reverted;
    });

    it("Should revert an execution from an unauthorized executor", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      await expect(anotherExecutorModule.executeViaAccount(smartAccountAddress, counterAddress, 0n, incrementNumber)).to.be.revertedWithCustomError(smartAccount, "InvalidModule");
    });

    it("Should revert on batch execution via MockExecutor", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");
      const revertOperation = counter.interface.encodeFunctionData("revertOperation");

      const execs = [
        {target: counterAddress, value: 0n, callData: incrementNumber}, 
        {target: counterAddress, value: 0n, callData: revertOperation},
        {target: counterAddress, value: 0n, callData: incrementNumber}];
      await expect(executorModule.execBatch(smartAccountAddress, execs)).to.be.revertedWith("Counter: Revert operation");
    });
  });
});
