import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, keccak256, solidityPacked } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  K1ValidatorFactory,
  EntryPoint,
  MockValidator,
  Nexus,
  BiconomyMetaFactory,
  NexusAccountFactory,
  Bootstrap,
  BootstrapUtil,
  MockHook,
  ModuleWhitelistFactory,
  MockExecutor,
  MockHandler,
} from "../../../typechain-types";
import {
  deployContractsAndSAFixture,
  deployContractsFixture,
} from "../utils/deployment";
import { encodeData, to18 } from "../utils/encoding";
import { buildPackedUserOp } from "../utils/operationHelpers";
import { BootstrapConfigStruct } from "../../../typechain-types/contracts/factory/K1ValidatorFactory";
import { toBytes, zeroAddress } from "viem";
import { GENERIC_FALLBACK_SELECTOR } from "../utils/erc7579Utils";

describe("Nexus Factory Tests", function () {
  let factory: K1ValidatorFactory;
  let smartAccount: Nexus;
  let entryPoint: EntryPoint;
  let validatorModule: MockValidator;
  let validatorModuleAddress: AddressLike;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let bundler: Signer;
  let bundlerAddress: AddressLike;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccountImplementation;
    validatorModule = setup.mockValidator;
    factory = setup.nexusFactory;

    validatorModuleAddress = await validatorModule.getAddress();
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    bundler = ethers.Wallet.createRandom();
    bundlerAddress = await bundler.getAddress();

    const accountOwnerAddress = ownerAddress;

    const saDeploymentIndex = 0;

    await factory.createAccount(accountOwnerAddress, saDeploymentIndex);
  });

  describe("Nexus K1ValidatorFactory tests", function () {
    it("Should deploy smart account with createAccount", async function () {
      const saDeploymentIndex = 100;

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
      );

      await expect(
        factory.createAccount(ownerAddress, saDeploymentIndex),
      ).to.emit(factory, "AccountCreated");

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy smart account with createAccount using a different index", async function () {
      const saDeploymentIndex = 25;

      const unexpectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        1,
      );

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
      );

      expect(unexpectedAccountAddress).to.not.equal(expectedAccountAddress);

      await factory.createAccount(ownerAddress, saDeploymentIndex);

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy smart account via handleOps", async function () {
      const saDeploymentIndex = 1;

      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
      );

      // factory address + factory data
      const initCode = ethers.concat([
        await factory.getAddress(),
        factory.interface.encodeFunctionData("createAccount", [
          ownerAddress,
          saDeploymentIndex,
        ]),
      ]);

      const userOp = buildPackedUserOp({
        sender: expectedAccountAddress,
        initCode: initCode,
        callData: "0x",
      });

      const userOpNonce = await entryPoint.getNonce(
        expectedAccountAddress,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );
      userOp.nonce = userOpNonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const userOpSignature = await owner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = userOpSignature;

      await entryPoint.depositTo(expectedAccountAddress, { value: to18(1) });
      await entryPoint.handleOps([userOp], bundlerAddress);

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should prevent account reinitialization", async function () {
      const response = smartAccount.initializeAccount("0x");
      await expect(response).to.be.revertedWithCustomError(
        smartAccount,
        "LinkedList_AlreadyInitialized()",
      );
    });
  });

  describe("Biconomy Meta Factory tests", function () {
    let metaFactory: BiconomyMetaFactory;
    let factory: NexusAccountFactory;
    let bootstrap: Bootstrap;
    let validatorModule: MockValidator;
    let bootstrapUtil: BootstrapUtil;
    let hookModule: MockHook;
    let owner: Signer;

    let parsedValidator: BootstrapConfigStruct;
    let parsedHook: BootstrapConfigStruct;
    let ownerAddress: AddressLike;

    beforeEach(async function () {
      const setup = await loadFixture(deployContractsAndSAFixture);
      entryPoint = setup.entryPoint;
      smartAccount = setup.deployedNexus;
      owner = setup.accountOwner;
      metaFactory = setup.metaFactory;
      factory = setup.nexusFactory;
      bootstrap = setup.bootstrap;
      validatorModule = setup.mockValidator;
      bootstrapUtil = setup.bootstrapUtil;
      hookModule = setup.mockHook;

      ownerAddress = await owner.getAddress();

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );

      parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      parsedHook = {
        module: hook[0],
        data: hook[1],
      };
    });

    it("Should add factory to whitelist", async function () {
      await metaFactory.addFactoryToWhitelist(await factory.getAddress());

      expect(
        await metaFactory.factoryWhitelist(await factory.getAddress()),
      ).to.equal(true);
      expect(
        await metaFactory.isWhitelisted(await factory.getAddress()),
      ).to.equal(true);
    });

    it("Should remove from factory whitelist", async function () {
      await metaFactory.removeFactoryFromWhitelist(await factory.getAddress());

      expect(
        await metaFactory.factoryWhitelist(await factory.getAddress()),
      ).to.equal(false);
      expect(
        await metaFactory.isWhitelisted(await factory.getAddress()),
      ).to.equal(false);
    });

    it("Should not work to deploy Nexus account, factory is not whitelisted", async function () {
      const salt = keccak256("0x");
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
      );
      const factoryData = factory.interface.encodeFunctionData(
        "createAccount",
        [initData, salt],
      );
      await expect(
        metaFactory.deployWithFactory(await factory.getAddress(), factoryData),
      ).to.be.revertedWithCustomError(metaFactory, "FactoryNotWhitelisted()");
    });

    it("Should deploy Nexus account", async function () {
      await metaFactory.addFactoryToWhitelist(await factory.getAddress());
      const salt = keccak256("0x");
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
      );
      const factoryData = factory.interface.encodeFunctionData(
        "createAccount",
        [initData, salt],
      );
      await expect(
        metaFactory.deployWithFactory(await factory.getAddress(), factoryData),
      ).to.emit(factory, "AccountCreated");
    });

    it("Should revert, wrong initData", async function () {
      await metaFactory.addFactoryToWhitelist(await factory.getAddress());
      const salt = keccak256("0x");
      const factoryData = factory.interface.encodeFunctionData(
        "createAccount",
        ["0x", salt],
      );
      await expect(
        metaFactory.deployWithFactory(await factory.getAddress(), factoryData),
      ).to.be.reverted;
    });
  });

  describe("Nexus Account Factory tests", function () {
    let smartAccount: Nexus;
    let entryPoint: EntryPoint;
    let metaFactory: BiconomyMetaFactory;
    let factory: NexusAccountFactory;
    let bootstrap: Bootstrap;
    let validatorModule: MockValidator;
    let bootstrapUtil: BootstrapUtil;
    let hookModule: MockHook;
    let owner: Signer;
    let smartAccountImplementation: Nexus;

    let parsedValidator: BootstrapConfigStruct;
    let parsedHook: BootstrapConfigStruct;
    let ownerAddress: AddressLike;
    let entryPointAddress: AddressLike;

    beforeEach(async function () {
      const setup = await loadFixture(deployContractsAndSAFixture);
      entryPoint = setup.entryPoint;
      smartAccount = setup.deployedNexus;
      owner = setup.accountOwner;
      entryPointAddress = await setup.entryPoint.getAddress();
      metaFactory = setup.metaFactory;
      factory = setup.nexusFactory;
      bootstrap = setup.bootstrap;
      validatorModule = setup.mockValidator;
      bootstrapUtil = setup.bootstrapUtil;
      hookModule = setup.mockHook;
      smartAccountImplementation = setup.smartAccountImplementation;

      ownerAddress = await owner.getAddress();

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );

      parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      parsedHook = {
        module: hook[0],
        data: hook[1],
      };
    });

    it("Should check implementation address", async function () {
      expect(await factory.ACCOUNT_IMPLEMENTATION()).to.equal(
        await smartAccountImplementation.getAddress(),
      );
    });

    it("Should revert, implementation address cannot be zero", async function () {
      const ContractFactory = await ethers.getContractFactory(
        "NexusAccountFactory",
        owner,
      );
      await expect(
        ContractFactory.deploy(zeroAddress, owner),
      ).to.be.revertedWithCustomError(
        factory,
        "ImplementationAddressCanNotBeZero()",
      );
    });

    it("Should compute address", async function () {
      const salt = keccak256("0x");
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
      );
      const address = await factory.computeAccountAddress(initData, salt);
      console.log("Address: ", address);
    });

    it("Should deploy Nexus account", async function () {
      const salt = keccak256("0x");
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
      );
      await expect(factory.createAccount(initData, salt)).to.emit(
        factory,
        "AccountCreated",
      );
    });
  });

  describe("Module Whitelist Factory tests", function () {
    let smartAccount: Nexus;
    let entryPoint: EntryPoint;
    let moduleWhitelistFactory: ModuleWhitelistFactory;
    let factory: NexusAccountFactory;
    let bootstrap: Bootstrap;
    let validatorModule: MockValidator;
    let fallbackModule: MockHandler;
    let bootstrapUtil: BootstrapUtil;
    let hookModule: MockHook;
    let owner: Signer;
    let mockExecutor: MockExecutor;

    let parsedValidator: BootstrapConfigStruct;
    let parsedHook: BootstrapConfigStruct;
    let ownerAddress: AddressLike;
    let entryPointAddress: AddressLike;

    beforeEach(async function () {
      const setup = await loadFixture(deployContractsAndSAFixture);
      entryPoint = setup.entryPoint;
      smartAccount = setup.deployedNexus;
      owner = setup.accountOwner;
      entryPointAddress = await setup.entryPoint.getAddress();
      moduleWhitelistFactory = setup.moduleWhitelistFactory;
      factory = setup.nexusFactory;
      bootstrap = setup.bootstrap;
      validatorModule = setup.mockValidator;
      bootstrapUtil = setup.bootstrapUtil;
      hookModule = setup.mockHook;
      fallbackModule = setup.mockFallbackHandler;
      mockExecutor = setup.mockExecutor;

      ownerAddress = await owner.getAddress();

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );

      parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      parsedHook = {
        module: hook[0],
        data: hook[1],
      };
    });

    it("Add module to whitelist", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await validatorModule.getAddress(),
      );
      expect(
        await moduleWhitelistFactory.moduleWhitelist(
          await validatorModule.getAddress(),
        ),
      ).to.equal(true);
    });

    it("Remove module from whitelist", async function () {
      await moduleWhitelistFactory.removeModuleFromWhitelist(
        await validatorModule.getAddress(),
      );
      expect(
        await moduleWhitelistFactory.moduleWhitelist(
          await validatorModule.getAddress(),
        ),
      ).to.equal(false);
    });

    it("Create account with modules", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await validatorModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await hookModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await mockExecutor.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await fallbackModule.getAddress(),
      );

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );
      const executor = await bootstrapUtil.makeBootstrapConfigSingle(
        await mockExecutor.getAddress(),
        "0x",
      );
      const fallback = await bootstrapUtil.makeBootstrapConfigSingle(
        await fallbackModule.getAddress(),
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      const parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      const parsedHook = {
        module: hook[0],
        data: hook[1],
      };
      const parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };
      const parsedFallback = {
        module: fallback[0],
        data: fallback[1],
      };

      const salt = keccak256(toBytes(1));
      const initData = await bootstrap.getInitNexusCalldata(
        [parsedValidator],
        [parsedExecutor],
        parsedHook,
        [parsedFallback],
      );

      await expect(
        moduleWhitelistFactory.createAccount(initData, salt),
      ).to.emit(moduleWhitelistFactory, "AccountCreated");

      await moduleWhitelistFactory.computeAccountAddress(initData, salt);
    });

    it("Should revert when creating account with validator not whitelisted", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await hookModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await mockExecutor.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await fallbackModule.getAddress(),
      );

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );
      const executor = await bootstrapUtil.makeBootstrapConfigSingle(
        await mockExecutor.getAddress(),
        "0x",
      );
      const fallback = await bootstrapUtil.makeBootstrapConfigSingle(
        await fallbackModule.getAddress(),
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      const parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      const parsedHook = {
        module: hook[0],
        data: hook[1],
      };
      const parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };
      const parsedFallback = {
        module: fallback[0],
        data: fallback[1],
      };

      const salt = keccak256(toBytes(1));
      const initData = await bootstrap.getInitNexusCalldata(
        [parsedValidator],
        [parsedExecutor],
        parsedHook,
        [parsedFallback],
      );

      await expect(moduleWhitelistFactory.createAccount(initData, salt)).to.be
        .reverted;
    });

    it("Should revert when creating account with hook not whitelisted", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await validatorModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await mockExecutor.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await fallbackModule.getAddress(),
      );

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );
      const executor = await bootstrapUtil.makeBootstrapConfigSingle(
        await mockExecutor.getAddress(),
        "0x",
      );
      const fallback = await bootstrapUtil.makeBootstrapConfigSingle(
        await fallbackModule.getAddress(),
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      const parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      const parsedHook = {
        module: hook[0],
        data: hook[1],
      };
      const parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };
      const parsedFallback = {
        module: fallback[0],
        data: fallback[1],
      };

      const salt = keccak256(toBytes(1));
      const initData = await bootstrap.getInitNexusCalldata(
        [parsedValidator],
        [parsedExecutor],
        parsedHook,
        [parsedFallback],
      );

      await expect(moduleWhitelistFactory.createAccount(initData, salt)).to.be
        .reverted;
    });

    it("Should revert when creating account with executor not whitelisted", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await validatorModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await hookModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await fallbackModule.getAddress(),
      );

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );
      const executor = await bootstrapUtil.makeBootstrapConfigSingle(
        await mockExecutor.getAddress(),
        "0x",
      );
      const fallback = await bootstrapUtil.makeBootstrapConfigSingle(
        await fallbackModule.getAddress(),
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      const parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      const parsedHook = {
        module: hook[0],
        data: hook[1],
      };
      const parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };
      const parsedFallback = {
        module: fallback[0],
        data: fallback[1],
      };

      const salt = keccak256(toBytes(1));
      const initData = await bootstrap.getInitNexusCalldata(
        [parsedValidator],
        [parsedExecutor],
        parsedHook,
        [parsedFallback],
      );

      await expect(moduleWhitelistFactory.createAccount(initData, salt)).to.be
        .reverted;
    });

    it("Should revert when creating account with fallback handler not whitelisted", async function () {
      await moduleWhitelistFactory.addModuleToWhitelist(
        await validatorModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await hookModule.getAddress(),
      );
      await moduleWhitelistFactory.addModuleToWhitelist(
        await mockExecutor.getAddress(),
      );

      const validator = await bootstrapUtil.makeBootstrapConfigSingle(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await bootstrapUtil.makeBootstrapConfigSingle(
        await hookModule.getAddress(),
        "0x",
      );
      const executor = await bootstrapUtil.makeBootstrapConfigSingle(
        await mockExecutor.getAddress(),
        "0x",
      );
      const fallback = await bootstrapUtil.makeBootstrapConfigSingle(
        await fallbackModule.getAddress(),
        encodeData(["bytes4"], [GENERIC_FALLBACK_SELECTOR]),
      );

      const parsedValidator = {
        module: validator[0],
        data: validator[1],
      };
      const parsedHook = {
        module: hook[0],
        data: hook[1],
      };
      const parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };
      const parsedFallback = {
        module: fallback[0],
        data: fallback[1],
      };

      const salt = keccak256(toBytes(1));
      const initData = await bootstrap.getInitNexusCalldata(
        [parsedValidator],
        [parsedExecutor],
        parsedHook,
        [parsedFallback],
      );

      await expect(moduleWhitelistFactory.createAccount(initData, salt)).to.be
        .reverted;
    });
  });
});
