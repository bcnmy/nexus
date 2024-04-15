import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { EntryPoint, MockExecutor, MockHandler, MockHook, MockValidator, SmartAccount } from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import {
  deployContractsAndSAFixture,
} from "../utils/deployment";
import { buildPackedUserOp, findEventInLogs, generateUseropCallData } from "../utils/operationHelpers";
import { encodeData } from "../utils/encoding";
import { GENERIC_FALLBACK_SELECTOR, installModule } from "../utils/erc7579Utils";

describe("SmartAccount Module Management Tests", () => {
  
  let deployedMSA: SmartAccount;
  let mockValidator: MockValidator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let moduleAddress: AddressLike;
  let mockExecutor: MockExecutor;
  let accountOwner: Signer;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let mockHook: MockHook;
  let mockFallbackHandler: MockHandler;
  let hookModuleAddress: AddressLike;
  let mockFallbackHandlerAddress: AddressLike;

  before(async function () {
    ({ deployedMSA, mockValidator, mockExecutor, accountOwner, entryPoint, mockHook, mockFallbackHandler } =
      await deployContractsAndSAFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    moduleAddress = await mockValidator.getAddress();
    mockExecutor = mockExecutor;
    accountOwner = accountOwner;
    entryPoint = entryPoint;
    hookModuleAddress = await mockHook.getAddress();
    mockFallbackHandlerAddress = await mockFallbackHandler.getAddress();

    bundler = ethers.Wallet.createRandom();
  });

  describe("Basic Module Management Tests", () => {
    it("Should correctly get installed validators", async () => {
      const validators = await deployedMSA.getValidatorsPaginated("0x0000000000000000000000000000000000000001", 100);
      expect(validators[0].length).to.be.equal(1);
      expect(validators[0][0]).to.be.equal(await mockValidator.getAddress());
    });
  
    it("Should correctly get installed executors", async () => {
      let executors = await deployedMSA.getExecutorsPaginated("0x0000000000000000000000000000000000000001", 100);
      expect(executors[0].length).to.be.equal(0);
      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockExecutor, validatorModule: mockValidator, moduleType: ModuleType.Execution, accountOwner, bundler })
      executors = await deployedMSA.getExecutorsPaginated("0x0000000000000000000000000000000000000001", 100);
      expect(executors[0].length).to.be.equal(1);
      expect(executors[0][0]).to.be.equal(await mockExecutor.getAddress());
    });

    it("Should throw if module type id is not valid", async () => {
      const invalidModuleType = 100;
      const response = await installModule({ deployedMSA, entryPoint, moduleToInstall: mockExecutor, validatorModule: mockValidator, moduleType: invalidModuleType, accountOwner, bundler })
      const receipt = await response.wait();
      const event = findEventInLogs(receipt.logs, "UserOperationRevertReason");
      
      expect(event).to.equal("UserOperationRevertReason");
    });
  
    it("Should correctly get active hook", async () => {
      const activeHook = await deployedMSA.getActiveHook();
      expect(activeHook).to.be.equal("0x0000000000000000000000000000000000000000");
    });
  
    it("Should correctly get active fallback handler", async () => {
      const activeFallbackHandler = await deployedMSA.getFallbackHandlerBySelector(GENERIC_FALLBACK_SELECTOR);
      // no fallback handler installed
      expect(activeFallbackHandler[1]).to.be.equal("0x0000000000000000000000000000000000000000");
    });
  });

  describe("Validator Module Tests", () => {
    it("Should not be able to install wrong validator type", async () => {
      const functionCalldata = deployedMSA.interface.encodeFunctionData("installModule", [ModuleType.Hooks, await mockValidator.getAddress(), ethers.hexlify(await accountOwner.getAddress())]);
      await expect(
        mockExecutor.executeViaAccount(await deployedMSA.getAddress(), await deployedMSA.getAddress(), 0n, functionCalldata)
      ).to.be.revertedWithCustomError(deployedMSA, "IncompatibleHookModule");
    });

    it("Should not be able to uninstall last validator   module", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const functionCalldata = deployedMSA.interface.encodeFunctionData("uninstallModule", [ModuleType.Validation, await mockValidator.getAddress(), encodeData(["address", "bytes"], [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))])]);

      await expect(
        mockExecutor.executeViaAccount(await deployedMSA.getAddress(), await deployedMSA.getAddress(), 0n, functionCalldata)
      ).to.be.revertedWithCustomError(deployedMSA, "CannotRemoveLastValidator()");
    });
  });

  describe("Executor Module Tests", () => {
    it("Should correctly install a execution module on the smart account", async () => {
      // Current test this should be expected to be true as it's default enabled module

      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockExecutor, validatorModule: mockValidator, moduleType: ModuleType.Execution, accountOwner, bundler })
  
      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      )
  
      expect(isInstalledAfter).to.be.true;
    });

    it("Should correctly uninstall a previously installed execution module by using the execution module itself", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const functionCalldata = deployedMSA.interface.encodeFunctionData("uninstallModule", [ModuleType.Execution, await mockExecutor.getAddress(), encodeData(["address", "bytes"], [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))])]);

      await mockExecutor.executeViaAccount(await deployedMSA.getAddress(), await deployedMSA.getAddress(), 0n, functionCalldata)
  
      const isInstalled = await deployedMSA.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      )

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed execution module via entryPoint", async () => {
      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockExecutor, moduleType: ModuleType.Execution, validatorModule: mockValidator, accountOwner, bundler })

      const isInstalledBefore = await deployedMSA.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      )
      
      expect(isInstalledBefore).to.be.true;

      let prevAddress = "0x0000000000000000000000000000000000000001";

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedMSA,
        functionName: "uninstallModule",
        args: [ModuleType.Execution, await mockExecutor.getAddress(), encodeData(["address", "bytes"], [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))])],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedMSA.getAddress(),
        callData: uninstallModuleData,
      });
  
      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes((await mockValidator.getAddress()).toString(), 24),
      );
      userOp.nonce = nonce; 
  
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = signature;

      const balance = await ethers.provider.getBalance(await deployedMSA.getAddress())

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      )

      expect(isInstalledAfter).to.be.false;
    });
  });

  describe("Hook Module Tests", () => {
    it("Should correctly install a hook module on the smart account", async () => {
      expect(
        await deployedMSA.isModuleInstalled(
          ModuleType.Hooks,
          hookModuleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;

      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockHook, validatorModule: mockValidator, moduleType: ModuleType.Hooks, accountOwner, bundler })
  
      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      )

      const activeHook = await deployedMSA.getActiveHook();
  
      expect(activeHook).to.equal(await mockHook.getAddress())
      expect(isInstalledAfter).to.be.true;
    });

    it("Should correctly uninstall a previously installed hook module by using the execution module", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      
      const functionCalldata = deployedMSA.interface.encodeFunctionData("uninstallModule", [ModuleType.Hooks, hookModuleAddress, encodeData(["address", "bytes"], [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))])]);

      // Need to install the executor module back on the smart account
      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockExecutor, moduleType: ModuleType.Execution, validatorModule: mockValidator, accountOwner, bundler })

      await mockExecutor.executeViaAccount(await deployedMSA.getAddress(), await deployedMSA.getAddress(), 0n, functionCalldata)
  
      const isInstalled = await deployedMSA.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      )

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed hook module via entryPoint", async () => {
      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockHook, moduleType: ModuleType.Hooks, validatorModule: mockValidator, accountOwner, bundler })

      const isInstalledBefore = await deployedMSA.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      )
      
      expect(isInstalledBefore, "Module should not be installed before").to.be.true;

      let prevAddress = "0x0000000000000000000000000000000000000001";

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedMSA,
        functionName: "uninstallModule",
        args: [ModuleType.Hooks, hookModuleAddress, encodeData(["address", "bytes"], [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))])],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedMSA.getAddress(),
        callData: uninstallModuleData,
      });
  
      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes((await mockValidator.getAddress()).toString(), 24),
      );
      userOp.nonce = nonce; 
  
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = signature;

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      )

      expect(isInstalledAfter, "Module should not be installed after").to.be.false;
    });
  });

  describe("Fallback Handler Module Tests", () => {
    it("Should correctly install a fallback handler module on the smart account", async () => {
      expect(
        await deployedMSA.isModuleInstalled(
          ModuleType.Fallback,
          mockFallbackHandlerAddress,
          encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])
        ), "Module should not be installed before"
      ).to.be.false;

      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockFallbackHandler, validatorModule: mockValidator, moduleType: ModuleType.Fallback, accountOwner, bundler, initData: encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]) })
  
      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])
      )
  
      expect(isInstalledAfter, "Module should be installed after").to.be.true;
    });

    it("Should correctly uninstall a previously installed fallback handler module by using the execution module", async () => {
      const functionCalldata = deployedMSA.interface.encodeFunctionData("uninstallModule", [ModuleType.Fallback, mockFallbackHandlerAddress, encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])]);

      await mockExecutor.executeViaAccount(await deployedMSA.getAddress(), await deployedMSA.getAddress(), 0n, functionCalldata)
  
      const isInstalled = await deployedMSA.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])
      )

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed fallback handler module via entryPoint", async () => {
      await installModule({ deployedMSA, entryPoint, moduleToInstall: mockFallbackHandler, moduleType: ModuleType.Fallback, validatorModule: mockValidator, accountOwner, bundler, initData: encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])})

      const isInstalledBefore = await deployedMSA.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])
      )
      
      expect(isInstalledBefore, "Module should not be installed before").to.be.true;

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedMSA,
        functionName: "uninstallModule",
        args: [ModuleType.Fallback, mockFallbackHandlerAddress, encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedMSA.getAddress(),
        callData: uninstallModuleData,
      });
  
      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes((await mockValidator.getAddress()).toString(), 24),
      );
      userOp.nonce = nonce; 
  
      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = signature;

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedMSA.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR])
      )

      expect(isInstalledAfter, "Module should not be installed after").to.be.false;
    });
  });
});
