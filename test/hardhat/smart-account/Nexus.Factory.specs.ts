import { ethers } from "hardhat";
import { expect } from "chai";
import {
  AddressLike,
  Signer,
  ZeroAddress,
  keccak256,
  solidityPacked,
} from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  K1ValidatorFactory,
  EntryPoint,
  MockValidator,
  Nexus,
  BiconomyMetaFactory,
  NexusAccountFactory,
  NexusBootstrap,
  BootstrapLib,
  MockHook,
  MockRegistry,
  MockExecutor,
} from "../../../typechain-types";
import {
  deployContractsAndSAFixture,
  deployContractsFixture,
} from "../utils/deployment";
import { to18 } from "../utils/encoding";
import {
  MODE_VALIDATION,
  buildPackedUserOp,
  getNonce,
  numberTo3Bytes,
} from "../utils/operationHelpers";
import { BootstrapConfigStruct } from "../../../typechain-types/contracts/lib/BootstrapLib";

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
  let initData: string;

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

    await factory.createAccount(accountOwnerAddress, saDeploymentIndex, [], 0);
  });

  describe("Nexus K1ValidatorFactory tests", function () {
    it("Should deploy smart account with createAccount", async function () {
      const saDeploymentIndex = 100;

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      await expect(
        factory.createAccount(ownerAddress, saDeploymentIndex, [], 0),
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
        [],
        0,
      );

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      expect(unexpectedAccountAddress).to.not.equal(expectedAccountAddress);

      await factory.createAccount(ownerAddress, saDeploymentIndex, [], 0);

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy smart account via handleOps", async function () {
      const saDeploymentIndex = 1;

      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      // factory address + factory data
      const initCode = ethers.concat([
        await factory.getAddress(),
        factory.interface.encodeFunctionData("createAccount", [
          ownerAddress,
          saDeploymentIndex,
          [],
          0,
        ]),
      ]);

      const userOp = buildPackedUserOp({
        sender: expectedAccountAddress,
        initCode: initCode,
        callData: "0x",
      });

      const userOpNonce = await getNonce(
        entryPoint,
        expectedAccountAddress,
        MODE_VALIDATION,
        validatorModuleAddress.toString(),
        numberTo3Bytes(1),
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
      await expect(smartAccount.initializeAccount("0x00000000000000000000000000000000123456784e4e4e4e")).to.be.rejectedWith(
        "reverted with an unrecognized custom error (return data: 0xaed59595)", // NotInitializable()
      );
    });
  });

  describe("Biconomy Meta Factory tests", function () {
    let metaFactory: BiconomyMetaFactory;
    let factory: NexusAccountFactory;
    let bootstrap: NexusBootstrap;
    let validatorModule: MockValidator;
    let BootstrapLib: BootstrapLib;
    let hookModule: MockHook;
    let registry: MockRegistry;
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
      BootstrapLib = setup.BootstrapLib;
      hookModule = setup.mockHook;
      registry = setup.registry;

      ownerAddress = await owner.getAddress();

      const validator = {
        module: await validatorModule.getAddress(),
        data: solidityPacked(["address"], [ownerAddress]),
      };

      const hook = {
        module: await hookModule.getAddress(),
        data: "0x",
      };

      parsedValidator = {
        module: validator.module,
        data: validator.data,
      };
      parsedHook = {
        module: hook.module,
        data: hook.data,
      };

      initData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "bytes"],
        [
          await bootstrap.getAddress(),
          bootstrap.interface.encodeFunctionData(
            "initNexusScoped",
            [
              [parsedValidator],
              parsedHook,
              {
                registry: await registry.getAddress(),
                attesters: [],
                threshold: 0n,
              },
            ],
          ),
        ],
      );
    });

    it("Should add factory to whitelist", async function () {
      await metaFactory.addFactoryToWhitelist(await factory.getAddress());

      expect(
        await metaFactory.factoryWhitelist(await factory.getAddress()),
      ).to.equal(true);
      expect(
        await metaFactory.isFactoryWhitelisted(await factory.getAddress()),
      ).to.equal(true);
    });

    it("Should remove from factory whitelist", async function () {
      await metaFactory.removeFactoryFromWhitelist(await factory.getAddress());

      expect(
        await metaFactory.factoryWhitelist(await factory.getAddress()),
      ).to.equal(false);
      expect(
        await metaFactory.isFactoryWhitelisted(await factory.getAddress()),
      ).to.equal(false);
    });

    it("Should not work to deploy Nexus account, factory is not whitelisted", async function () {
      const salt = keccak256("0x");

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
        ["0xffffffff", salt],
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
    let bootstrap: NexusBootstrap;
    let validatorModule: MockValidator;
    let executorModule: MockExecutor;
    let BootstrapLib: BootstrapLib;
    let hookModule: MockHook;
    let registry: MockRegistry;
    let owner: Signer;
    let smartAccountImplementation: Nexus;

    let parsedValidator: BootstrapConfigStruct;
    let parsedExecutor: BootstrapConfigStruct;
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
      BootstrapLib = setup.BootstrapLib;
      hookModule = setup.mockHook;
      executorModule = setup.mockExecutor;
      registry = setup.registry;
      smartAccountImplementation = setup.smartAccountImplementation;

      ownerAddress = await owner.getAddress();

      const validator = {
        module: await validatorModule.getAddress(),
        data: solidityPacked(["address"], [ownerAddress]),
      };
      const executor = {
        module: await executorModule.getAddress(),
        data: "0x",
      };
      const hook = {
        module: await hookModule.getAddress(),
        data: "0x",
      };

      parsedValidator = {
        module: validator.module,
        data: validator.data,
      };

      parsedExecutor = {
        module: executor.module,
        data: executor.data,
      };

      parsedHook = {
        module: hook.module,
        data: hook.data,
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
        ContractFactory.deploy(ZeroAddress, owner),
      ).to.be.revertedWithCustomError(
        factory,
        "ImplementationAddressCanNotBeZero()",
      );
    });

    it("Should compute address", async function () {
      const salt = keccak256("0x");
      const address = await factory.computeAccountAddress(initData, salt);
    });

    it("Should deploy Nexus account", async function () {
      const salt = keccak256("0x");

      await expect(factory.createAccount(initData, salt)).to.emit(
        factory,
        "AccountCreated",
      );
    });

    it("Should revert with NexusInitializationFailed when delegatecall fails", async function () {
      // Get the actual bootstrap address
      const bootstrapAddress = await bootstrap.getAddress();

      // Manually corrupt the bootstrapCall data to cause failure
      const corruptedBootstrapCall = "0x12345678"; // Invalid data

      // Encode the corrupted init data
      const corruptedInitData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "bytes"],
        [bootstrapAddress, corruptedBootstrapCall],
      );

      // Replace the original bootstrapCall with corrupted one in initData
      const salt = keccak256("0x");

      // Expect the transaction to revert with NexusInitializationFailed due to delegatecall failure
      await expect(
        factory.createAccount(corruptedInitData, salt),
      ).to.be.revertedWithCustomError(
        smartAccountImplementation,
        "NexusInitializationFailed",
      );
    });
  });
});
