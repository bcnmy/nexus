import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, ZeroAddress } from "ethers";
import {
  EntryPoint,
  K1Validator,
  MockExecutor,
  MockHandler,
  MockHook,
  MockValidator,
  Nexus,
} from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import {
  buildPackedUserOp,
  findEventInLogs,
  generateUseropCallData,
  getNonce,
  MODE_VALIDATION,
  numberTo3Bytes,
} from "../utils/operationHelpers";
import { encodeData } from "../utils/encoding";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  GENERIC_FALLBACK_SELECTOR,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
  installModule,
} from "../utils/erc7579Utils";

describe("Nexus Module Management Tests", () => {
  let deployedNexus: Nexus;
  let mockValidator: MockValidator;
  let ecdsaValidator: K1Validator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let moduleAddress: AddressLike;
  let mockExecutor: MockExecutor;
  let accountOwner: Signer;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let mockHook: MockHook;
  let mockHook2: MockHook;
  let mockFallbackHandler: MockHandler;
  let hookModuleAddress: AddressLike;
  let hookModuleAddress2: AddressLike;
  let mockFallbackHandlerAddress: AddressLike;

  before(async function () {
    ({
      deployedNexus,
      mockValidator,
      mockExecutor,
      accountOwner,
      entryPoint,
      mockHook,
      mockHook2,
      ecdsaValidator,
      mockFallbackHandler,
    } = await deployContractsAndSAFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    moduleAddress = await mockValidator.getAddress();
    ecdsaValidator = ecdsaValidator;
    mockExecutor = mockExecutor;
    accountOwner = accountOwner;
    entryPoint = entryPoint;
    hookModuleAddress = await mockHook.getAddress();
    hookModuleAddress2 = await mockHook2.getAddress();
    mockFallbackHandlerAddress = await mockFallbackHandler.getAddress();

    bundler = ethers.Wallet.createRandom();
  });

  describe("Basic Module Management Tests", () => {
    it("Should correctly get installed validators", async () => {
      const validators = await deployedNexus.getValidatorsPaginated(
        "0x0000000000000000000000000000000000000001",
        100,
      );
      expect(validators[0].length).to.be.equal(1);
      expect(validators[0][0]).to.be.equal(await mockValidator.getAddress());
    });

    it("Should correctly get installed executors", async () => {
      let executors = await deployedNexus.getExecutorsPaginated(
        "0x0000000000000000000000000000000000000001",
        100,
      );
      expect(executors[0].length).to.be.equal(0);
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        validatorModule: mockValidator,
        moduleType: ModuleType.Execution,
        accountOwner,
        bundler,
      });
      executors = await deployedNexus.getExecutorsPaginated(
        "0x0000000000000000000000000000000000000001",
        100,
      );
      expect(executors[0].length).to.be.equal(1);
      expect(executors[0][0]).to.be.equal(await mockExecutor.getAddress());
    });

    it("Should throw if module type id is not valid", async () => {
      const invalidModuleType = 100;
      const response = await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        validatorModule: mockValidator,
        moduleType: invalidModuleType,
        accountOwner,
        bundler,
      });
      const receipt = await response.wait();
      const event = findEventInLogs(receipt.logs, "UserOperationRevertReason");

      expect(event).to.equal("UserOperationRevertReason");
    });

    it("Should correctly get active hook", async () => {
      const activeHook = await deployedNexus.getActiveHook();
      expect(activeHook).to.be.equal(ZeroAddress);
    });

    it("Should correctly get active fallback handler", async () => {
      const activeFallbackHandler =
        await deployedNexus.getFallbackHandlerBySelector(
          GENERIC_FALLBACK_SELECTOR,
        );
      // no fallback handler installed
      expect(activeFallbackHandler[1]).to.be.equal(ZeroAddress);
    });
  });

  describe("Validator Module Tests", () => {
    it("Should not be able to install wrong validator type", async () => {
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "installModule",
        [
          ModuleType.Validation,
          await hookModuleAddress,
          ethers.hexlify(await accountOwner.getAddress()),
        ],
      );
      await expect(
        mockExecutor.executeViaAccount(
          await deployedNexus.getAddress(),
          await deployedNexus.getAddress(),
          0n,
          functionCalldata,
        ),
      ).to.be.revertedWithCustomError(deployedNexus, "MismatchModuleTypeId");
    });

    it("Should not be able to uninstall last validator   module", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Validation,
          await mockValidator.getAddress(),
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      );

      await expect(
        mockExecutor.executeViaAccount(
          await deployedNexus.getAddress(),
          await deployedNexus.getAddress(),
          0n,
          functionCalldata,
        ),
      ).to.be.revertedWithCustomError(
        deployedNexus,
        "CanNotRemoveLastValidator()",
      );
    });

    it("Should revert with AccountAccessUnauthorized", async () => {
      const installModuleData = deployedNexus.interface.encodeFunctionData(
        "installModule",
        [
          ModuleType.Validation,
          await mockValidator.getAddress(),
          ethers.hexlify(await accountOwner.getAddress()),
        ],
      );

      const executionCalldata = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [await deployedNexus.getAddress(), "0", installModuleData],
      );

      await expect(
        deployedNexus.execute(
          ethers.concat([
            CALLTYPE_SINGLE,
            EXECTYPE_DEFAULT,
            MODE_DEFAULT,
            UNUSED,
            MODE_PAYLOAD,
          ]),
          executionCalldata,
        ),
      ).to.be.reverted;
    });
  });

  describe("Executor Module Tests", () => {
    it("Should correctly install a execution module on the smart account", async () => {
      // Current test this should be expected to be true as it's default enabled module

      await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        validatorModule: mockValidator,
        moduleType: ModuleType.Execution,
        accountOwner,
        bundler,
      });

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      );

      expect(isInstalledAfter).to.be.true;
    });

    it("Should revert with AccountAccessUnauthorized", async () => {
      const installModuleData = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Execution,
          await mockExecutor.getAddress(),
          ethers.hexlify("0x"),
        ],
      );

      const executionCalldata = ethers.solidityPacked(
        ["address", "uint256", "bytes"],
        [await deployedNexus.getAddress(), "0", installModuleData],
      );

      await expect(
        deployedNexus.execute(
          ethers.concat([
            CALLTYPE_SINGLE,
            EXECTYPE_DEFAULT,
            MODE_DEFAULT,
            UNUSED,
            MODE_PAYLOAD,
          ]),
          executionCalldata,
        ),
      ).to.be.reverted;
    });

    it("Should not be able to uninstall a module which is not installed", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const randomAddress = await ethers.Wallet.createRandom().getAddress();
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Execution,
          randomAddress,
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      );

      await expect(
        mockExecutor.executeViaAccount(
          await deployedNexus.getAddress(),
          await deployedNexus.getAddress(),
          0n,
          functionCalldata,
        ),
      ).to.be.reverted;
    });

    it("Should correctly uninstall a previously installed execution module by using the execution module itself", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Execution,
          await mockExecutor.getAddress(),
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      );

      await mockExecutor.executeViaAccount(
        await deployedNexus.getAddress(),
        await deployedNexus.getAddress(),
        0n,
        functionCalldata,
      );

      const isInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      );

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed execution module via entryPoint", async () => {
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        moduleType: ModuleType.Execution,
        validatorModule: mockValidator,
        accountOwner,
        bundler,
      });

      const isInstalledBefore = await deployedNexus.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      );

      expect(isInstalledBefore).to.be.true;

      let prevAddress = "0x0000000000000000000000000000000000000001";

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedNexus,
        functionName: "uninstallModule",
        args: [
          ModuleType.Execution,
          await mockExecutor.getAddress(),
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData: uninstallModuleData,
      });

      const nonce = await getNonce(
        entryPoint,
        userOp.sender,
        MODE_VALIDATION,
        await mockValidator.getAddress(),
        numberTo3Bytes(1),
      );
      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Execution,
        await mockExecutor.getAddress(),
        ethers.hexlify("0x"),
      );

      expect(isInstalledAfter).to.be.false;
    });
  });

  describe("Hook Module Tests", () => {
    it("Should correctly install a hook module on the smart account", async () => {
      expect(
        await deployedNexus.isModuleInstalled(
          ModuleType.Hooks,
          hookModuleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;

      await installModule({
        deployedNexus,
        entryPoint,
        module: mockHook,
        validatorModule: mockValidator,
        moduleType: ModuleType.Hooks,
        accountOwner,
        bundler,
      });

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      );

      const activeHook = await deployedNexus.getActiveHook();

      expect(activeHook).to.equal(await mockHook.getAddress());
      expect(isInstalledAfter).to.be.true;
    });

    it("Should throw HookAlreadyInstalled if trying to install the same hook again.", async () => {
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        moduleType: ModuleType.Execution,
        validatorModule: mockValidator,
        accountOwner,
        bundler,
      });

      expect(
        await deployedNexus.isModuleInstalled(
          ModuleType.Execution,
          await mockExecutor.getAddress(),
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      const installHookData = deployedNexus.interface.encodeFunctionData(
        "installModule",
        [
          ModuleType.Hooks,
          await mockHook.getAddress(),
          ethers.hexlify(await accountOwner.getAddress()),
        ],
      );

      await expect(
        mockExecutor.executeViaAccount(
          await deployedNexus.getAddress(),
          await deployedNexus.getAddress(),
          0n,
          installHookData,
        ),
      ).to.be.revertedWithCustomError(deployedNexus, "HookAlreadyInstalled");
    });

    it("Should throw HookAlreadyInstalled if trying to install two different hooks", async () => {
      expect(
        await deployedNexus.isModuleInstalled(
          ModuleType.Hooks,
          hookModuleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      const installSecondHook = deployedNexus.interface.encodeFunctionData(
        "installModule",
        [
          ModuleType.Hooks,
          hookModuleAddress2,
          ethers.hexlify(await accountOwner.getAddress()),
        ],
      );

      await expect(
        mockExecutor.executeViaAccount(
          await deployedNexus.getAddress(),
          await deployedNexus.getAddress(),
          0n,
          installSecondHook,
        ),
      ).to.be.revertedWithCustomError(deployedNexus, "HookAlreadyInstalled");
    });

    it("Should correctly uninstall a previously installed hook module by using the execution module", async () => {
      let prevAddress = "0x0000000000000000000000000000000000000001";

      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Hooks,
          hookModuleAddress,
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      );

      // Need to install the executor module back on the smart account
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockExecutor,
        moduleType: ModuleType.Execution,
        validatorModule: mockValidator,
        accountOwner,
        bundler,
      });

      await mockExecutor.executeViaAccount(
        await deployedNexus.getAddress(),
        await deployedNexus.getAddress(),
        0n,
        functionCalldata,
      );

      const isInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed hook module via entryPoint", async () => {
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockHook,
        moduleType: ModuleType.Hooks,
        validatorModule: mockValidator,
        accountOwner,
        bundler,
      });

      const isInstalledBefore = await deployedNexus.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isInstalledBefore, "Module should not be installed before").to.be
        .true;

      let prevAddress = "0x0000000000000000000000000000000000000001";

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedNexus,
        functionName: "uninstallModule",
        args: [
          ModuleType.Hooks,
          hookModuleAddress,
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData: uninstallModuleData,
      });

      const nonce = await getNonce(
        entryPoint,
        userOp.sender,
        MODE_VALIDATION,
        await mockValidator.getAddress(),
        numberTo3Bytes(11),
      );
      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Hooks,
        hookModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isInstalledAfter, "Module should not be installed after").to.be
        .false;
    });
  });

  describe("Fallback Handler Module Tests", () => {
    it("Should correctly install a fallback handler module on the smart account", async () => {
      expect(
        await deployedNexus.isModuleInstalled(
          ModuleType.Fallback,
          mockFallbackHandlerAddress,
          encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
        ),
        "Module should not be installed before",
      ).to.be.false;

      await installModule({
        deployedNexus,
        entryPoint,
        module: mockFallbackHandler,
        validatorModule: mockValidator,
        moduleType: ModuleType.Fallback,
        accountOwner,
        bundler,
        data: encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      });

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      expect(isInstalledAfter, "Module should be installed after").to.be.true;
    });

    it("Should correctly install a fallback handler module on the smart account", async () => {
      const exampleSender = await deployedNexus.getAddress();
      const exampleValue = 12345;
      const exampleData = ethers.getBytes("0x12345678");

      await expect(
        mockFallbackHandler.onGenericFallback(
          exampleSender,
          exampleValue,
          exampleData,
        ),
      )
        .to.emit(mockFallbackHandler, "GenericFallbackCalled")
        .withArgs(exampleSender, exampleValue, exampleData);
    });

    it("Should correctly uninstall a previously installed fallback handler module by using the execution module", async () => {
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Fallback,
          mockFallbackHandlerAddress,
          encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
        ],
      );

      await mockExecutor.executeViaAccount(
        await deployedNexus.getAddress(),
        await deployedNexus.getAddress(),
        0n,
        functionCalldata,
      );

      const isInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed validation module", async () => {
      const installModuleFuncCalldata =
        deployedNexus.interface.encodeFunctionData("installModule", [
          ModuleType.Validation,
          await ecdsaValidator.getAddress(),
          ethers.hexlify(await accountOwner.getAddress()),
        ]);

      await mockExecutor.executeViaAccount(
        await deployedNexus.getAddress(),
        await deployedNexus.getAddress(),
        0n,
        installModuleFuncCalldata,
      );

      const isInstalledFirst = await deployedNexus.isModuleInstalled(
        ModuleType.Validation,
        await ecdsaValidator.getAddress(),
        encodeData(
          ["address", "bytes"],
          [
            await mockValidator.getAddress(),
            ethers.hexlify(ethers.toUtf8Bytes("")),
          ],
        ),
      );

      console.log("isInstalledFirst", isInstalledFirst);
      expect(isInstalledFirst).to.be.true;

      let prevAddress = "0x0000000000000000000000000000000000000001";
      const functionCalldata = deployedNexus.interface.encodeFunctionData(
        "uninstallModule",
        [
          ModuleType.Validation,
          await ecdsaValidator.getAddress(),
          encodeData(
            ["address", "bytes"],
            [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
          ),
        ],
      );

      await mockExecutor.executeViaAccount(
        await deployedNexus.getAddress(),
        await deployedNexus.getAddress(),
        0n,
        functionCalldata,
      );

      const isInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Validation,
        await ecdsaValidator.getAddress(),
        encodeData(
          ["address", "bytes"],
          [prevAddress, ethers.hexlify(ethers.toUtf8Bytes(""))],
        ),
      );

      expect(isInstalled).to.be.false;
    });

    it("Should correctly uninstall a previously installed fallback handler module via entryPoint", async () => {
      await installModule({
        deployedNexus,
        entryPoint,
        module: mockFallbackHandler,
        moduleType: ModuleType.Fallback,
        validatorModule: mockValidator,
        accountOwner,
        bundler,
        data: encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      });

      const isInstalledBefore = await deployedNexus.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      expect(isInstalledBefore, "Module should not be installed before").to.be
        .true;

      const uninstallModuleData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: deployedNexus,
        functionName: "uninstallModule",
        args: [
          ModuleType.Fallback,
          mockFallbackHandlerAddress,
          encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
        ],
      });

      const userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData: uninstallModuleData,
      });

      const nonce = await getNonce(
        entryPoint,
        userOp.sender,
        MODE_VALIDATION,
        await mockValidator.getAddress(),
        numberTo3Bytes(12),
      );
      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      await entryPoint.handleOps([userOp], await bundler.getAddress());

      const isInstalledAfter = await deployedNexus.isModuleInstalled(
        ModuleType.Fallback,
        mockFallbackHandlerAddress,
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      expect(isInstalledAfter, "Module should not be installed after").to.be
        .false;
    });
  });
});
