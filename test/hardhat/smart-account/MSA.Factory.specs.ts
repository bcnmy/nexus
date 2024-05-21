import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, ZeroAddress, toBeHex } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  K1ValidatorFactory,
  EntryPoint,
  MockValidator,
  Nexus,
} from "../../../typechain-types";
import { deployContractsFixture } from "../utils/deployment";
import { encodeData, to18 } from "../utils/encoding";
import { buildPackedUserOp } from "../utils/operationHelpers";

describe("Nexus Factory Tests", function () {
  let factory: K1ValidatorFactory;
  let smartAccount: Nexus;
  let entryPoint: EntryPoint;
  let validatorModule: MockValidator;
  let accounts: Signer[];
  let addresses: string[] | AddressLike[];
  let factoryAddress: AddressLike;
  let entryPointAddress: AddressLike;
  let smartAccountAddress: AddressLike;
  let validatorModuleAddress: AddressLike;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let bundler: Signer;
  let bundlerAddress: AddressLike;
  let ownerSA: Nexus;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccountImplementation;
    validatorModule = setup.mockValidator;
    factory = setup.msaFactory;
    accounts = setup.accounts;
    addresses = setup.addresses;

    entryPointAddress = await entryPoint.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    validatorModuleAddress = await validatorModule.getAddress();
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
    const expectedAccountAddress = await factory.computeAccountAddress(
      accountOwnerAddress,
      saDeploymentIndex,
    );

    await factory.createAccount(
      accountOwnerAddress,
      saDeploymentIndex,
    );

    ownerSA = smartAccount.attach(expectedAccountAddress) as Nexus;
  });

  describe("Contract Deployment - Should not revert", function () {
    it("Should deploy smart account with createAccount", async function () {
      const saDeploymentIndex = 0;

      const installData = encodeData(["address"], [ownerAddress]); // Example data, customize as needed

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
      );

      await factory.createAccount(
        ownerAddress,
        saDeploymentIndex,
      );

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy smart account with createAccount using a different index", async function () {
      const saDeploymentIndex = 25;

      const installData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [ownerAddress],
      ); // Example data, customize as needed

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

      await factory.createAccount(
        ownerAddress,
        saDeploymentIndex,
      );

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });


    it("Should deploy smart account via handleOps", async function () {
      const saDeploymentIndex = 1;

      const installData = ethers.solidityPacked(["address"], [ownerAddress]);

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
      const initData = smartAccount.interface.encodeFunctionData("initializeAccount", [
        "0x",
      ]);

      const response = smartAccount.initializeAccount(
        "0x"
      );
      await expect(response).to.be.revertedWithCustomError(
        smartAccount,
        "LinkedList_AlreadyInitialized()",
      );
    });
  });
});
