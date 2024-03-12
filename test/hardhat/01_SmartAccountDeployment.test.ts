import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  AccountFactory,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../typechain-types";
import { ModuleType } from "./utils/types";
import { deploySmartAccountFixture } from "./utils/deployment";
import { to18 } from "./utils/encoding";
import {
  generateFullInitCode,
  getAccountAddress,
  buildPackedUserOp,
} from "./utils/operationHelpers";

describe("SmartAccount Contract Integration Tests", function () {
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

  beforeEach(async function () {
    const setup = await loadFixture(deploySmartAccountFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccount;
    module = setup.module;
    factory = setup.factory;
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
  });

  describe("Contract Deployment", function () {
    it("Should deploy the SmartAccount contract successfully", async function () {
      // Checks if the smart account's address contains bytecode, indicating successful deployment
      expect(ethers.provider.getCode(smartAccountAddress)).to.not.equal("0x");
    });

    it("Should deploy the EntryPoint contract successfully", async function () {
      expect(ethers.provider.getCode(entryPointAddress)).to.not.equal("0x");
    });

    it("Should deploy the Module contract successfully", async function () {
      expect(ethers.provider.getCode(moduleAddress)).to.not.equal("0x");
    });

    it("Should handle account creation correctly, including when the account already exists", async function () {
      const SmartAccount = await ethers.getContractFactory("SmartAccount");

      const saDeploymentIndex = 0;

      const data = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [ownerAddress],
      ); // Example data, customize as needed

      // Read the expectec account address
      const expectedAccountAddress = await factory.getCounterFactualAddress(
        moduleAddress,
        data,
        saDeploymentIndex,
      );

      // First account creation attempt
      await factory.createAccount(moduleAddress, data, saDeploymentIndex);

      // Verify that the account was created
      const codeAfterFirstCreation = await ethers.provider.getCode(
        expectedAccountAddress,
      );
      expect(codeAfterFirstCreation).to.not.equal(
        "0x",
        "Account should have bytecode after the first creation attempt",
      );

      // Second account creation attempt with the same parameters
      await factory.createAccount(moduleAddress, data, saDeploymentIndex);

      // Verify that the account address remains the same and no additional deployment occurred
      const codeAfterSecondCreation = await ethers.provider.getCode(
        expectedAccountAddress,
      );
      expect(codeAfterSecondCreation).to.equal(
        codeAfterFirstCreation,
        "Account bytecode should remain unchanged after the second creation attempt",
      );
    });
  });

  describe("SmartAccount Deployment via EntryPoint", function () {
    it("Should successfully deploy a SmartAccount via the EntryPoint", async function () {
      const saDeploymentIndex = 0;
      // This involves preparing a user operation (userOp), signing it, and submitting it through the EntryPoint
      const initCode = await generateFullInitCode(
        ownerAddress,
        factoryAddress,
        moduleAddress,
        ModuleType.Validation,
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
      const saDeploymentIndex = 0;
      const initCode = await generateFullInitCode(
        ownerAddress,
        factoryAddress,
        moduleAddress,
        ModuleType.Validation,
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
