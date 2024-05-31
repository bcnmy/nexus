import { ExecutionMethod } from "../utils/types";
import { expect } from "chai";

import { Signer, parseEther } from "ethers";
import {
  K1ValidatorFactory,
  Counter,
  EntryPoint,
  MockExecutor,
  MockToken,
  MockValidator,
  Nexus,
} from "../../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import {
  generateUseropCallData,
  buildPackedUserOp,
} from "../utils/operationHelpers";
import { ethers } from "hardhat";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  EXECTYPE_TRY,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
  uninstallModule,
} from "../utils/erc7579Utils";
import { encodeData } from "../utils/encoding";

describe("Nexus Single Execution", () => {
  let factory: K1ValidatorFactory;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let validatorModule: MockValidator;
  let executorModule: MockExecutor;
  let counter: Counter;
  let alice: Signer;
  let smartAccount: Nexus;
  let smartAccountOwner: Signer;
  let deployer: Signer;

  let factoryAddress: string;
  let entryPointAddress: string;
  let bundlerAddress: string;
  let validatorModuleAddress: string;
  let executorModuleAddress: string;
  let counterAddress: string;
  let smartAccountAddress: string;
  let aliceAddress: string;
  let smartAccountOwnerAddress: string;
  let mockToken: MockToken;

  beforeEach(async () => {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    factory = setup.nexusK1Factory;
    bundler = ethers.Wallet.createRandom();
    validatorModule = setup.mockValidator;
    executorModule = setup.mockExecutor;
    smartAccountOwner = setup.accountOwner;
    alice = setup.aliceAccountOwner;
    smartAccount = setup.deployedNexus;
    counter = setup.counter;
    deployer = setup.deployer;
    mockToken = setup.mockToken;

    factoryAddress = await factory.getAddress();
    entryPointAddress = await entryPoint.getAddress();
    bundlerAddress = await bundler.getAddress();
    validatorModuleAddress = await validatorModule.getAddress();
    executorModuleAddress = await executorModule.getAddress();
    counterAddress = await counter.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    smartAccountOwnerAddress = await smartAccountOwner.getAddress();
    aliceAddress = await alice.getAddress();

    // First install the executor module on the smart account
    const isOwner = await validatorModule.isOwner(
      smartAccountAddress,
      smartAccountOwnerAddress,
    );

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
    const signature = await smartAccountOwner.signMessage(
      ethers.getBytes(userOpHash),
    );
    userOp.signature = signature;

    await entryPoint.handleOps([userOp], bundlerAddress);

    const isInstalled = await smartAccount.isModuleInstalled(
      ModuleType.Execution,
      executorModuleAddress,
      ethers.hexlify("0x"),
    );

    expect(isInstalled).to.be.true;
  });

  describe("Nexus Transaction Execution", () => {
    it("Should execute a transaction through handleOps", async () => {
      const isOwner = await validatorModule.isOwner(
        smartAccountAddress,
        smartAccountOwnerAddress,
      );
      expect(isOwner).to.be.true;
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
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      // Assert the counter's state (testing contract) before execution to ensure it's at its initial state.
      expect(await counter.getNumber()).to.equal(0);
      // Execute the signed userOp through the EntryPoint contract and verify the counter's state post-execution.

      await entryPoint.handleOps([userOp], bundlerAddress);

      expect(await counter.getNumber()).to.equal(1);
    });

    it("Should revert with AccountAccessUnauthorized, execute", async () => {
      const functionCallData =
        counter.interface.encodeFunctionData("incrementNumber");

      const executionCalldata = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [await counter.getAddress(), "0", functionCallData],
      );

      // expect this function call to revert
      await expect(
        smartAccount.execute(
          ethers.concat([
            CALLTYPE_SINGLE,
            EXECTYPE_DEFAULT,
            MODE_DEFAULT,
            UNUSED,
            MODE_PAYLOAD,
          ]),
          executionCalldata,
        ),
      ).to.be.revertedWithCustomError(
        smartAccount,
        "AccountAccessUnauthorized",
      );
    });

    it("Should revert with AccountAccessUnauthorized, executeUserOp", async function () {
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const userOp = buildPackedUserOp({
        sender: await smartAccount.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const validatorModuleAddress = await validatorModule.getAddress();
      const nonce = await smartAccount.nonce(
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);

      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      await expect(
        smartAccount.executeUserOp(userOp, userOpHash),
      ).to.be.revertedWithCustomError(
        smartAccount,
        "AccountAccessUnauthorized",
      );
    });

    it("Should execute an empty transaction through handleOps", async () => {
      const isOwner = await validatorModule.isOwner(
        smartAccountAddress,
        smartAccountOwnerAddress,
      );
      expect(isOwner).to.be.true;
      const callData = "0x";

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
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      await expect(entryPoint.handleOps([userOp], bundlerAddress)).to.not.be
        .reverted;
    });

    it("Should execute a token transfer through handleOps", async () => {
      const recipient = smartAccountOwnerAddress;
      const amount = parseEther("1");

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: mockToken,
        functionName: "transfer",
        args: [recipient, amount],
      });

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
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      const balanceBefore = await mockToken.balanceOf(recipient);
      await expect(entryPoint.handleOps([userOp], bundlerAddress)).to.not.be
        .reverted;
      const balanceAfter = await mockToken.balanceOf(recipient);

      expect(balanceAfter).to.equal(balanceBefore + amount);
    });

    it("Should approve and transferFrom", async () => {
      const amount = parseEther("1");

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: mockToken,
        functionName: "approve",
        args: [aliceAddress, amount],
      });

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
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      await expect(entryPoint.handleOps([userOp], bundlerAddress)).to.not.be
        .reverted;
      const allowanceAfter = await mockToken.allowance(
        smartAccountAddress,
        aliceAddress,
      );

      expect(allowanceAfter).to.equal(amount, "Not enough tokens approved");

      await mockToken
        .connect(alice)
        .transferFrom(smartAccountAddress, aliceAddress, amount);
      const aliceTokenBalance = await mockToken.balanceOf(aliceAddress);
      expect(aliceTokenBalance).to.equal(
        amount,
        "Not enough tokens transferred to Alice",
      );
    });

    it("Should execute a transaction via MockExecutor directly", async () => {
      const incrementNumber =
        counter.interface.encodeFunctionData("incrementNumber");

      const numberBefore = await counter.getNumber();
      await executorModule.executeViaAccount(
        smartAccountAddress,
        counterAddress,
        0n,
        incrementNumber,
      );

      const numberAfter = await counter.getNumber();

      expect(numberAfter).to.be.greaterThan(numberBefore);
    });

    it("Should transfer value via MockExecutor directly", async () => {
      const randomAddress = ethers.Wallet.createRandom().address;
      await deployer.sendTransaction({ to: smartAccountAddress, value: 1 });

      await executorModule.executeViaAccount(
        smartAccountAddress,
        randomAddress,
        1n,
        "0x",
      );

      const balance = await deployer.provider.getBalance(randomAddress);
      expect(balance).to.be.equal(1);
    });

    it("Should execute a transaction via MockExecutor using Entrypoint handleOps", async () => {
      const incrementNumber =
        counter.interface.encodeFunctionData("incrementNumber");

      const data = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: executorModule,
        functionName: "executeViaAccount",
        args: [smartAccountAddress, counterAddress, 0n, incrementNumber],
      });

      const incrementNumberUserOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData: data,
      });

      const incrementNumberUserOpNonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      incrementNumberUserOp.nonce = incrementNumberUserOpNonce;

      const incrementNumberUserOpHash = await entryPoint.getUserOpHash(
        incrementNumberUserOp,
      );
      const incrementNumberUserOpSignature =
        await smartAccountOwner.signMessage(
          ethers.getBytes(incrementNumberUserOpHash),
        );
      incrementNumberUserOp.signature = incrementNumberUserOpSignature;

      const numberBefore = await counter.getNumber();
      await entryPoint.handleOps([incrementNumberUserOp], bundlerAddress);
      const numberAfter = await counter.getNumber();

      expect(numberAfter).to.be.greaterThan(numberBefore);
    });

    it("Should revert the execution of a transaction through the EntryPoint using execute", async () => {
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "revertOperation",
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
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      const tx = await entryPoint.handleOps([userOp], bundlerAddress);
      // The tx will not revert, but the user operation will be reverted.
      await expect(tx).to.not.be.reverted;

      // Counter should be 0 if user operation has been reverted.
      expect(await counter.getNumber()).to.equal(0);
    });

    it("Should revert with InvalidModule custom error, through direct call to executor, module not installed.", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const incrementNumber =
        counter.interface.encodeFunctionData("incrementNumber");
      await uninstallModule({
        deployedNexus: smartAccount,
        entryPoint,
        module: executorModule,
        validatorModule: validatorModule,
        moduleType: ModuleType.Execution,
        accountOwner: smartAccountOwner,
        bundler,
      });
      const isInstalled = await smartAccount.isModuleInstalled(
        ModuleType.Execution,
        await executorModule.getAddress(),
        ethers.hexlify("0x"),
      );
      if (isInstalled) {
        const functionCalldata = smartAccount.interface.encodeFunctionData(
          "uninstallModule",
          [
            ModuleType.Execution,
            await executorModule.getAddress(),
            encodeData(
              ["address", "bytes"],
              [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
            ),
          ],
        );
        await executorModule.executeViaAccount(
          smartAccountAddress,
          smartAccountAddress,
          0n,
          functionCalldata,
        );
      }
      await expect(
        executorModule.executeViaAccount(
          smartAccountAddress,
          counterAddress,
          0n,
          incrementNumber,
        ),
      ).to.be.rejected;
    });

    it("Should revert without a reason, through direct call to executor. Wrong smart account address given to executeViaAccount()", async () => {
      const randomAddress = ethers.Wallet.createRandom().address;
      const incrementNumber =
        counter.interface.encodeFunctionData("incrementNumber");

      await expect(
        executorModule.executeViaAccount(
          randomAddress,
          counterAddress,
          0n,
          incrementNumber,
        ),
      ).to.be.reverted;
    });

    it("Should revert an execution from an unauthorized executor", async () => {
      const incrementNumber =
        counter.interface.encodeFunctionData("incrementNumber");
      const prevAddress = "0x0000000000000000000000000000000000000001";
      await uninstallModule({
        deployedNexus: smartAccount,
        entryPoint,
        module: executorModule,
        validatorModule: validatorModule,
        moduleType: ModuleType.Execution,
        accountOwner: smartAccountOwner,
        bundler,
        data: encodeData(
          ["address", "bytes"],
          [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
        ),
      });
      const isInstalled = await smartAccount.isModuleInstalled(
        ModuleType.Execution,
        await executorModule.getAddress(),
        ethers.hexlify(ethers.toUtf8Bytes("")),
      );

      expect(isInstalled).to.be.false;

      await expect(
        executorModule.executeViaAccount(
          smartAccountAddress,
          counterAddress,
          0n,
          incrementNumber,
        ),
      ).to.be.revertedWithCustomError(smartAccount, "InvalidModule");
    });
  });

  describe("Nexus Try Execute", () => {
    it("Should execute single user op using EXECTYPE_TRY", async () => {
      const mode = ethers.concat([
        CALLTYPE_SINGLE,
        EXECTYPE_TRY,
        MODE_DEFAULT,
        UNUSED,
        MODE_PAYLOAD,
      ]);
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
        mode,
      });

      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      userOp.nonce = nonce;
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      const numberBefore = await counter.getNumber();
      await entryPoint.handleOps([userOp], bundlerAddress);
      const numberAfter = await counter.getNumber();

      expect(numberAfter - numberBefore).to.be.equal(1);
    });
  });
});
