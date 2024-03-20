import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, toBeHex } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  AccountFactory,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { ModuleType } from "../utils/types";
import { deployContractsFixture } from "../utils/deployment";
import { to18, toBytes32 } from "../utils/encoding";
import {
  getInitCode,
  getAccountAddress,
  buildPackedUserOp,
} from "../utils/operationHelpers";
import { CALLTYPE_BATCH, CALLTYPE_SINGLE, EXECTYPE_DEFAULT, EXECTYPE_DELEGATE, EXECTYPE_TRY, MODE_DEFAULT, MODE_PAYLOAD, UNUSED } from "../utils/erc7579Utils";

describe("SmartAccount Basic Specs", function () {
  let factory: AccountFactory;
  let smartAccount: SmartAccount;
  let entryPoint: EntryPoint;
  let module: MockValidator;
  let accounts: Signer[];
  let addresses: string[] | AddressLike[];
  let factoryAddress: AddressLike;
  let entryPointAddress: AddressLike;
  let smartAccountAddress: AddressLike;
  let moduleAddress: AddressLike;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let bundler: Signer;
  let bundlerAddress: AddressLike;
  let userSA: SmartAccount;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccountImplementation;
    module = setup.mockValidator;
    factory = setup.msaFactory;
    accounts = setup.accounts;
    addresses = setup.addresses;

    entryPointAddress = await entryPoint.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    moduleAddress = await module.getAddress();
    factoryAddress = await factory.getAddress();
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    bundler = ethers.Wallet.createRandom();
    bundlerAddress = await bundler.getAddress();

    const accountOwnerAddress = ownerAddress;

    const saDeploymentIndex = 0;

    const installData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [accountOwnerAddress],
      ); // Example data, customize as needed
    
    // Read the expected account address
    const expectedAccountAddress = await factory.getCounterFactualAddress(
        moduleAddress, // validator address
        installData,
        saDeploymentIndex,
      );

    await factory.createAccount(moduleAddress, installData, saDeploymentIndex);

    userSA = smartAccount.attach(expectedAccountAddress) as SmartAccount;
  });

  describe("Contract Deployment", function () {
    it("Should deploy smart account", async function () {
      const saDeploymentIndex = 0;

      const installData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [ownerAddress],
      ); // Example data, customize as needed

      // Read the expected account address
      const expectedAccountAddress = await factory.getCounterFactualAddress(
        moduleAddress, // validator address
        installData,
        saDeploymentIndex,
      );

      await factory.createAccount(moduleAddress, installData, saDeploymentIndex);

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(
        expectedAccountAddress,
      );
      expect(proxyCode).to.not.equal(
        "0x",
        "Account should have bytecode",
      );
    });
  });

  describe("Account ID and Supported Modes", function () {
    it("Should correctly return the SmartAccount's ID", async function () {
      expect(await userSA.accountId()).to.equal(
        "biconomy.modular-smart-account.1.0.0-alpha",
      );
    });

    it("Should verify supported account modes", async function () {
      expect(await userSA.supportsExecutionMode(
        ethers.concat(
         [
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22)
        ])
        )
       )
        .to.be
        .true;
        expect(await userSA.supportsExecutionMode(ethers.concat([ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),ethers.zeroPadValue(toBeHex(UNUSED), 4),ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22)]))).to.be
        .true;


      expect(await userSA.supportsExecutionMode(
        ethers.concat(
          [
              ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
              ethers.zeroPadValue(toBeHex(CALLTYPE_BATCH), 1),
              ethers.zeroPadValue(toBeHex(UNUSED), 4),
              ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
              ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22)
        ])
        )
      )
        .to.be
        .true;


      expect(await userSA.supportsExecutionMode(
         ethers.concat(
            [
               ethers.zeroPadValue(toBeHex(EXECTYPE_TRY), 1),
               ethers.zeroPadValue(toBeHex(CALLTYPE_BATCH), 1),
               ethers.zeroPadValue(toBeHex(UNUSED), 4),
               ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
               ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22)
            ])
            )
        )
        .to.be
        .true;

      expect(await userSA.supportsExecutionMode(
         ethers.concat(
            [
                ethers.zeroPadValue(toBeHex(EXECTYPE_DELEGATE), 1),
                ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
                ethers.zeroPadValue(toBeHex(UNUSED), 4),
                ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
                ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22)
            ])
            )
        )
        .to.be
        .false;
    });

    it("Should confirm support for specified module types", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(await userSA.supportsModule(ModuleType.Validation)).to.be
        .true;
      expect(await userSA.supportsModule(ModuleType.Execution)).to.be
        .true;
    });
  });

  describe("SmartAccount Deployment via EntryPoint", function () {
    it("Should successfully deploy a SmartAccount via the EntryPoint", async function () {
      const saDeploymentIndex = 1;
      // This involves preparing a user operation (userOp), signing it, and submitting it through the EntryPoint
      const initCode = await getInitCode(
        ownerAddress,
        factoryAddress,
        moduleAddress, // validatorAddress
        saDeploymentIndex,
      );

      // Module initialization data, encoded
      const moduleInitData = ethers.solidityPacked(["address"], [ownerAddress]);

      const accountAddress = await factory.getCounterFactualAddress(
        moduleAddress,
        moduleInitData,
        saDeploymentIndex,
      );

      const nonce = await entryPoint.getNonce(
        accountAddress,
        ethers.zeroPadBytes(moduleAddress.toString(), 24),
      );

      const packedUserOp = buildPackedUserOp({
        sender: accountAddress,
        nonce,
        initCode,
      });

      const userOpHash = await entryPoint.getUserOpHash(packedUserOp);

      const sig = await owner.signMessage(ethers.getBytes(userOpHash));

      packedUserOp.signature = sig;

      await entryPoint.depositTo(accountAddress, { value: to18(1) });

      await entryPoint.handleOps([packedUserOp], bundlerAddress);
    });

    it("Should fail SmartAccount deployment with an unauthorized signer", async function () {
      const saDeploymentIndex = 2;
      const initCode = await getInitCode(
        ownerAddress,
        factoryAddress,
        moduleAddress,
        saDeploymentIndex,
      );
      // Module initialization data, encoded
      const moduleInitData = ethers.solidityPacked(["address"], [ownerAddress]);

      const accountAddress = await factory.getCounterFactualAddress(
        moduleAddress,
        moduleInitData,
        saDeploymentIndex,
      );

      const nonce = await entryPoint.getNonce(
        accountAddress,
        ethers.zeroPadBytes(moduleAddress.toString(), 24),
      );

      const packedUserOp = buildPackedUserOp({
        sender: accountAddress,
        nonce: nonce,
        initCode: initCode,
      });

      const userOpHash = await entryPoint.getUserOpHash(packedUserOp);

      const sig = await accounts[10].signMessage(ethers.getBytes(userOpHash));
      packedUserOp.signature = sig;
      await entryPoint.depositTo(accountAddress, { value: to18(1) });

      await expect(entryPoint.handleOps([packedUserOp], bundlerAddress))
        .to.be.revertedWithCustomError(entryPoint, "FailedOp")
        .withArgs(0, "AA24 signature error");
    });
  });
});
