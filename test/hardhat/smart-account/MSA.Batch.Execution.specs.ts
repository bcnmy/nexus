import { CALLTYPE_SINGLE, EXECTYPE_TRY, installModule } from './../utils/erc7579Utils';
import { ExecutionMethod } from '../utils/types';
import { expect } from "chai";

import { ContractTransactionResponse, Signer } from "ethers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockExecutor,
  MockToken,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import {
  generateUseropCallData,
  buildPackedUserOp,
  prepareUserOperation,
} from "../utils/operationHelpers";
import { ethers } from 'hardhat';
import { CALLTYPE_BATCH, EXECTYPE_DEFAULT, MODE_DEFAULT, MODE_PAYLOAD, UNUSED } from '../utils/erc7579Utils';
import { encodeData } from '../utils/encoding';

describe("SmartAccount Batch Execution", () => {
    let factory: AccountFactory;
    let entryPoint: EntryPoint;
    let bundler: Signer;
    let validatorModule: MockValidator;
    let executorModule: MockExecutor;
    let anotherExecutorModule: MockExecutor;
    let counter: Counter;
    let smartAccount: SmartAccount;
    let aliceSmartAccount: SmartAccount
    let smartAccountOwner: Signer;
    let smartAccountAliceOwner: Signer;
    let deployer: Signer;
    let mockToken: MockToken;
    let alice: Signer;

    let factoryAddress: string;
    let entryPointAddress: string;
    let bundlerAddress: string;
    let validatorModuleAddress: string;
    let executorModuleAddress: string;
    let counterAddress: string;
    let smartAccountAddress: string;
    let aliceSmartAccountAddress: string;
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
    smartAccountAliceOwner = setup.aliceAccountOwner;
    aliceSmartAccount = setup.aliceDeployedMSA;
    counter = setup.counter;
    deployer = setup.deployer;
    mockToken = setup.mockToken;
    alice = setup.accounts[3];

    factoryAddress = await factory.getAddress();
    entryPointAddress = await entryPoint.getAddress();
    bundlerAddress = await bundler.getAddress();
    validatorModuleAddress = await validatorModule.getAddress();
    executorModuleAddress = await executorModule.getAddress();
    counterAddress = await counter.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    aliceSmartAccountAddress = await aliceSmartAccount.getAddress();
    smartAccountOwnerAddress = await smartAccountOwner.getAddress();

    // First install the executor module on the smart account
    const isOwner = await validatorModule.isOwner(smartAccountAddress, smartAccountOwnerAddress);
                
    expect(isOwner).to.be.true;

    await installModule({ deployedMSA: smartAccount, entryPoint, moduleToInstall: executorModule, moduleType: ModuleType.Execution, validatorModule: validatorModule, accountOwner: smartAccountOwner, bundler })
    
    const isInstalled = await smartAccount.isModuleInstalled(
      ModuleType.Execution,
      executorModuleAddress,
      ethers.hexlify("0x"),
    )

    expect(isInstalled).to.be.true;
  });

  describe("SmartAccount Transaction Execution", () => {
    it("Should execute a batch of transactions via MockExecutor directly", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");

      const execs = [{target: counterAddress, value: 0n, callData: incrementNumber}, {target: counterAddress, value: 0n, callData: incrementNumber}];
      const numberBefore = await counter.getNumber();
      await executorModule.execBatch(smartAccountAddress, execs);
      const numberAfter = await counter.getNumber();

      expect(numberAfter - numberBefore).to.be.equal(2);
    });

    it("Should execute approve and transfer in one user operation through handleOps", async () => {
      const AccountExecution = await ethers.getContractFactory("SmartAccount");
      const amountToSpend = ethers.parseEther("1");

      const approveCalldata = mockToken.interface.encodeFunctionData("approve", [await alice.getAddress(), amountToSpend]);
      const transferCalldata = mockToken.interface.encodeFunctionData("transferFrom", [smartAccountAddress, await alice.getAddress(), amountToSpend]);
      const mode = ethers.concat([CALLTYPE_BATCH, EXECTYPE_DEFAULT, MODE_DEFAULT, UNUSED, MODE_PAYLOAD]);
    
      const approveExecData = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [await mockToken.getAddress(), 0, approveCalldata],
      );
      const transferExecData = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [await mockToken.getAddress(), 0, transferCalldata],
      );

      const executions = encodeData(["bytes[]"], [[approveExecData, transferExecData]]);
      const userOpCalldata = AccountExecution.interface.encodeFunctionData(
        "execute",
        [mode, encodeData(["bytes"], [executions])],
      );

      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: userOpCalldata,
      });
      const userOpNonce = await entryPoint.getNonce(smartAccountAddress, ethers.zeroPadBytes(validatorModuleAddress.toString(), 24));
      userOp.nonce = userOpNonce;
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const userOpSignature = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = userOpSignature;

      const allowanceBefore = await mockToken.allowance(smartAccountAddress, await alice.getAddress());
      const balanceBefore = await mockToken.balanceOf(await alice.getAddress());
      await entryPoint.handleOps([userOp], bundlerAddress);
      const allowanceAfter = await mockToken.allowance(smartAccountAddress, await alice.getAddress());
      const balanceAfter = await mockToken.balanceOf(await alice.getAddress());

      expect(balanceAfter - balanceBefore).to.be.equal(amountToSpend);
    });

    it("Should approve and transfer ERC20 token via direct call to executorModule", async () => {
      // Spender could be paymaster
      const spender = smartAccountAddress;
      const amountToSpend = ethers.parseEther("1.1");

      const approveCalldata = mockToken.interface.encodeFunctionData("approve", [spender, amountToSpend]);
      const transferCalldata = mockToken.interface.encodeFunctionData("transferFrom", [spender, await alice.getAddress(), amountToSpend]);

      const execs = [{target: await mockToken.getAddress(), value: 0n, callData: approveCalldata}, {target: await mockToken.getAddress(), value: 0n, callData: transferCalldata}];
      const balanceBefore = await mockToken.balanceOf(await alice.getAddress());
      await executorModule.execBatch(smartAccountAddress, execs); // Here we specify who will be the sender of the transactions

      const allowance = await mockToken.allowance(smartAccountAddress, spender);
      expect(allowance).to.be.equal(0, "Allowance should be 0 after transfer.");

      const balanceAfter = await mockToken.balanceOf(await alice.getAddress());
      expect(balanceAfter - balanceBefore).to.be.equal(amountToSpend);
    });

    it("Should approve and transfer ERC20 token via executorModule through handleOps", async () => {
      // Spender could be paymaster
      const spender = smartAccountAddress;
      const amountToSpend = ethers.parseEther("1");
      const approveCalldata = mockToken.interface.encodeFunctionData("approve", [spender, amountToSpend]);
      const transferCalldata = mockToken.interface.encodeFunctionData("transferFrom", [spender, await alice.getAddress(), amountToSpend]);
      const execs = [{target: await mockToken.getAddress(), value: 0n, callData: approveCalldata}, {target: await mockToken.getAddress(), value: 0n, callData: transferCalldata}];

      const userOpCalldata = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "execBatch", args: [smartAccountAddress, execs]});
      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: userOpCalldata,
      });
      const userOp1Nonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      userOp.nonce = userOp1Nonce; 
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const userOpSignature = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = userOpSignature;

      const balanceBefore = await mockToken.balanceOf(await alice.getAddress());
      
      await entryPoint.handleOps([userOp], bundlerAddress);

      const balanceAfter = await mockToken.balanceOf(await alice.getAddress());
      const allowance = await mockToken.allowance(smartAccountAddress, spender); 

      expect(balanceAfter - balanceBefore).to.be.equal(amountToSpend);
    });

    it("Should approve and transfer ERC20 token via executorModule through handleOps in separate ops", async () => {
      // Spender could be paymaster
      const spender = smartAccountAddress;
      const amountToSpend = ethers.parseEther("1");
      const recipient = aliceSmartAccountAddress;

      const approveCalldata = mockToken.interface.encodeFunctionData("approve", [recipient, amountToSpend]);
      const transferCalldata = mockToken.interface.encodeFunctionData("transferFrom", [spender, recipient, amountToSpend]);

      // User op 1 - Approve tokens for transfer
      const data1 = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "executeViaAccount", args: [smartAccountAddress, await mockToken.getAddress(), 0n, approveCalldata]});

      const userOp1 = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: data1,
      });

      const userOp1Nonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      userOp1.nonce = userOp1Nonce; 

      const userOp1Hash = await entryPoint.getUserOpHash(userOp1);
      const userOp1Signature = await smartAccountOwner.signMessage(ethers.getBytes(userOp1Hash));
      userOp1.signature = userOp1Signature;

      // User op 2 - Transfer tokens
  
      // First install the executor module on Alice's smart account
      await installModule({ deployedMSA: aliceSmartAccount, entryPoint, moduleToInstall: executorModule, validatorModule: validatorModule, moduleType: ModuleType.Execution, accountOwner: smartAccountAliceOwner, bundler })

      const data2 = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "executeViaAccount", args: [aliceSmartAccountAddress, await mockToken.getAddress(), 0, transferCalldata]});
      const userOp2 = buildPackedUserOp({
        sender: aliceSmartAccountAddress,
        callData: data2,
      });

      const userOp2Nonce = await entryPoint.getNonce(
        aliceSmartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      userOp2.nonce = userOp2Nonce; 

      const userOp2Hash = await entryPoint.getUserOpHash(userOp2);
      const userOp2Signature = await smartAccountAliceOwner.signMessage(ethers.getBytes(userOp2Hash));
      userOp2.signature = userOp2Signature;
     
      // Check balances and allowances
      const balanceBefore = await mockToken.balanceOf(recipient);

      await entryPoint.handleOps([userOp1, userOp2], bundlerAddress);

      const allowanceAfter = await mockToken.allowance(spender, recipient);

      const balanceAfter = await mockToken.balanceOf(recipient);
      expect(balanceAfter - balanceBefore).to.be.equal(amountToSpend);
    });

    it("Should excecute a batch of empty transactions via MockExecutor directly", async () => {
      const execs = [];
      const results: ContractTransactionResponse = await executorModule.execBatch(smartAccountAddress, execs);
      
      expect(results.value).to.be.equal(0);
    });

    it("Should execute a batch of transactions via MockExecutor by using the entryPoint handleOps", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");
      const execs = [{target: counterAddress, value: 0n, callData: incrementNumber}, {target: counterAddress, value: 0n, callData: incrementNumber}];

      const data = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "execBatch", args: [smartAccountAddress, execs]});

      const incrementNumberBatchUserOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: data,
      });

      const incrementNumberUserOpNonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      incrementNumberBatchUserOp.nonce = incrementNumberUserOpNonce; 

      const incrementNumberUserOpHash = await entryPoint.getUserOpHash(incrementNumberBatchUserOp);
      const incrementNumberUserOpSignature = await smartAccountOwner.signMessage(ethers.getBytes(incrementNumberUserOpHash));
      incrementNumberBatchUserOp.signature = incrementNumberUserOpSignature;

      const numberBefore = await counter.getNumber();
      await entryPoint.handleOps([incrementNumberBatchUserOp], bundlerAddress);
      const numberAfter = await counter.getNumber();
      
      expect(numberAfter - numberBefore).to.equal(2);
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

  describe("SmartAccount Transaction Batch Execution using Try Execute", () => {
    it("Should increment counter even if one user operation fails", async () => {
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");
      const revertOperation = counter.interface.encodeFunctionData("revertOperation");
      const execs = [{target: counterAddress, value: 0n, callData: incrementNumber}, {target: counterAddress, value: 0, callData: revertOperation}, {target: counterAddress, value: 0n, callData: incrementNumber}];

      const mode = ethers.concat([CALLTYPE_BATCH, EXECTYPE_TRY, MODE_DEFAULT, UNUSED, MODE_PAYLOAD]);
      const callData = await generateUseropCallData({executionMethod: ExecutionMethod.Execute, targetContract: executorModule, functionName: "execBatch", args: [smartAccountAddress, execs], mode});

      let userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      userOp = await prepareUserOperation(userOp, entryPoint, validatorModuleAddress, smartAccountOwner, 0);

      const numberBefore = await counter.getNumber();
      const response = await entryPoint.handleOps([userOp], bundlerAddress);
      const receipt = await response.wait();
      console.log(receipt.logs, "receipt");
      
      const numberAfter = await counter.getNumber();
      console.log(numberAfter, "number after");
      
      // expect(numberAfter - numberBefore).to.be.equal(2);
  });
  });
});
