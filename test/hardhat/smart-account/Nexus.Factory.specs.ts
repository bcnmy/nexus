import { ethers } from "hardhat";
import { expect } from "chai";
import {
  AddressLike,
  Signer,
  ZeroAddress,
  ZeroHash,
  keccak256,
  solidityPacked,
  zeroPadBytes,
} from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  K1ValidatorFactory,
  EntryPoint,
  MockValidator,
  Nexus,
  BiconomyMetaFactory,
  NexusAccountFactory,
  Bootstrap,
  BootstrapLib,
  MockHook,
  MockRegistry,
  MockExecutor,
  RegistryFactory,
} from "../../../typechain-types";
import {
  deployContractsAndSAFixture,
  deployContractsFixture,
} from "../utils/deployment";
import { encodeData, to18 } from "../utils/encoding";
import {
  MODE_VALIDATION,
  buildPackedUserOp,
  getNonce,
  numberTo3Bytes,
} from "../utils/operationHelpers";
import { BootstrapConfigStruct } from "../../../typechain-types/contracts/lib/BootstrapLib";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

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

      const validator = await BootstrapLib.createSingleConfig(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );
      const hook = await BootstrapLib.createSingleConfig(
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
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
        registry,
        [],
        0,
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
        registry,
        [],
        0,
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

      const validator = await BootstrapLib.createSingleConfig(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );

      const executor = await BootstrapLib.createSingleConfig(
        await executorModule.getAddress(),
        "0x",
      );
      const hook = await BootstrapLib.createSingleConfig(
        await hookModule.getAddress(),
        "0x",
      );

      parsedValidator = {
        module: validator[0],
        data: validator[1],
      };

      parsedExecutor = {
        module: executor[0],
        data: executor[1],
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
        ContractFactory.deploy(ZeroAddress, owner),
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
        registry,
        [],
        0,
      );
      const address = await factory.computeAccountAddress(initData, salt);
    });

    it("Should deploy Nexus account", async function () {
      const salt = keccak256("0x");
      const initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
        registry,
        [],
        0,
      );

      await expect(factory.createAccount(initData, salt)).to.emit(
        factory,
        "AccountCreated",
      );
    });

    it("Should revert with NexusInitializationFailed when delegatecall fails", async function () {
      // Get the actual bootstrap address
      const bootstrapAddress = await bootstrap.getAddress();

      // Generate valid initialization data
      let initData = await bootstrap.getInitNexusScopedCalldata(
        [parsedValidator],
        parsedHook,
        registry,
        [],
        0,
      );

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

    it("Should revert with NoValidatorInstalled if no validator is installed after initialization", async function () {
      // Set up a valid bootstrap address but do not include any validators in the initData
      const validBootstrapAddress = await owner.getAddress();
      const bootstrapData = "0x"; // Valid but does not install any validators

      const initData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "bytes"],
        [validBootstrapAddress, bootstrapData],
      );

      const salt = keccak256("0x");

      await expect(
        factory.createAccount(initData, salt),
      ).to.be.revertedWithCustomError(
        smartAccountImplementation,
        "NoValidatorInstalled",
      );
    });
  });

  describe("RegistryFactory", function () {
    let smartAccount: Nexus;
    let entryPoint: EntryPoint;
    let factory: RegistryFactory;
    let bootstrap: Bootstrap;
    let validatorModule: MockValidator;
    let executorModule: MockExecutor;
    let BootstrapLib: BootstrapLib;
    let hookModule: MockHook;
    let registryFactory: RegistryFactory;
    let owner: Signer;
    let mockRegistry: MockRegistry;
    let smartAccountImplementation: Nexus;

    let parsedValidator: BootstrapConfigStruct;
    let parsedExecutor: BootstrapConfigStruct;
    let parsedHook: BootstrapConfigStruct;
    let ownerAddress: AddressLike;
    let entryPointAddress: AddressLike;
    let attester1: Signer;
    let attester2: Signer;
    let nonOwner: Signer;
    const threshold = 1;

    beforeEach(async function () {
      const setup = await loadFixture(deployContractsAndSAFixture);
      entryPoint = setup.entryPoint;
      smartAccount = setup.deployedNexus;
      owner = setup.accountOwner;
      entryPointAddress = await setup.entryPoint.getAddress();
      [, , , , attester1, attester2, nonOwner] = await ethers.getSigners();

      const RegistryFactory =
        await ethers.getContractFactory("RegistryFactory");
      bootstrap = setup.bootstrap;
      validatorModule = setup.mockValidator;
      BootstrapLib = setup.BootstrapLib;
      hookModule = setup.mockHook;
      executorModule = setup.mockExecutor;
      mockRegistry = setup.registry;
      smartAccountImplementation = setup.smartAccountImplementation;
      registryFactory = await RegistryFactory.deploy(
        await smartAccount.getAddress(),
        await owner.getAddress(),
        await mockRegistry.getAddress(),
        [await attester1.getAddress()],
        1,
      );

      registryFactory = registryFactory.connect(owner);

      ownerAddress = await owner.getAddress();

      const validator = await BootstrapLib.createSingleConfig(
        await validatorModule.getAddress(),
        solidityPacked(["address"], [ownerAddress]),
      );

      const executor = await BootstrapLib.createSingleConfig(
        await executorModule.getAddress(),
        "0x",
      );
      const hook = await BootstrapLib.createSingleConfig(
        await hookModule.getAddress(),
        "0x",
      );

      parsedValidator = {
        module: validator[0],
        data: validator[1],
      };

      parsedExecutor = {
        module: executor[0],
        data: executor[1],
      };

      parsedHook = {
        module: hook[0],
        data: hook[1],
      };
    });

    describe("Deployment", function () {
      it("Should set the correct owner, implementation, and registry", async function () {
        expect(await registryFactory.owner()).to.equal(
          await owner.getAddress(),
        );
        expect(await registryFactory.ACCOUNT_IMPLEMENTATION()).to.equal(
          await smartAccount.getAddress(),
        );
        expect(await registryFactory.REGISTRY()).to.equal(
          await mockRegistry.getAddress(),
        );
      });

      it("Should revert if implementation address is zero", async function () {
        const RegistryFactory =
          await ethers.getContractFactory("RegistryFactory");
        await expect(
          RegistryFactory.deploy(
            ethers.ZeroAddress,
            await owner.getAddress(),
            await mockRegistry.getAddress(),
            [await attester1.getAddress()],
            threshold,
          ),
        ).to.be.revertedWithCustomError(
          registryFactory,
          "ImplementationAddressCanNotBeZero",
        );
      });

      it("Should revert if owner address is zero", async function () {
        const RegistryFactory =
          await ethers.getContractFactory("RegistryFactory");
        await expect(
          RegistryFactory.deploy(
            await smartAccount.getAddress(),
            ethers.ZeroAddress,
            await mockRegistry.getAddress(),
            [await attester1.getAddress()],
            threshold,
          ),
        ).to.be.revertedWithCustomError(
          registryFactory,
          "ZeroAddressNotAllowed",
        );
      });

      it("Should revert if threshold is greater than the number of attesters", async function () {
        const RegistryFactory =
          await ethers.getContractFactory("RegistryFactory");
        await expect(
          RegistryFactory.deploy(
            await smartAccount.getAddress(),
            await owner.getAddress(),
            await mockRegistry.getAddress(),
            [await attester1.getAddress()],
            2,
          ),
        )
          .to.be.revertedWithCustomError(registryFactory, "InvalidThreshold")
          .withArgs(2, 1);
      });
    });

    describe("Attester Management", function () {
      it("Should allow owner to add an attester", async function () {
        await registryFactory.addAttester(await attester2.getAddress());
        const attesters = await registryFactory.getAttesters();
        expect(attesters).to.include(await attester2.getAddress());
      });

      it("Should sort attesters after adding", async function () {
        await registryFactory.addAttester(await attester2.getAddress());
        const attesters = await registryFactory.getAttesters();
        expect(attesters).to.deep.equal(
          [await attester1.getAddress(), await attester2.getAddress()].sort(),
        );
      });

      it("Should allow owner to remove an attester", async function () {
        await registryFactory.removeAttester(await attester1.getAddress());
        const attesters = await registryFactory.getAttesters();
        expect(attesters).to.not.include(await attester1.getAddress());
      });

      it("Should revert if non-owner tries to add or remove attester", async function () {
        await expect(
          registryFactory
            .connect(nonOwner)
            .addAttester(await attester2.getAddress()),
        ).to.be.revertedWithCustomError(registryFactory, "Unauthorized");
        await expect(
          registryFactory
            .connect(nonOwner)
            .removeAttester(await attester1.getAddress()),
        ).to.be.revertedWithCustomError(registryFactory, "Unauthorized");
      });
    });

    describe("Threshold Management", function () {
      it("Should allow owner to set a new threshold", async function () {
        await registryFactory.setThreshold(2);
        expect(await registryFactory.threshold()).to.equal(2);
      });

      it("Should revert if non-owner tries to set a new threshold", async function () {
        await expect(
          registryFactory.connect(nonOwner).setThreshold(2),
        ).to.be.revertedWithCustomError(registryFactory, "Unauthorized");
      });
    });
  });
});
