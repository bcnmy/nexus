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
import { BootstrapConfigStruct } from "../../../typechain-types/contracts/lib/BootstrapLib";

describe("Nexus Factory Tests", function () {
  let factory: NexusAccountFactory;
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
