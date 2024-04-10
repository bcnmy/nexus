import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, ZeroAddress, toBeHex } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  AccountFactory,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { ModuleType } from "../utils/types";
import { deployContractsFixture } from "../utils/deployment";
import { to18 } from "../utils/encoding";
import {
  getInitCode,
  buildPackedUserOp,
} from "../utils/operationHelpers";
import {
  CALLTYPE_BATCH,
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  EXECTYPE_DELEGATE,
  EXECTYPE_TRY,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
} from "../utils/erc7579Utils";
import { encodeFunctionData } from "viem";

describe("SmartAccount Factory Tests", function () {
  let factory: AccountFactory;
  let smartAccount: SmartAccount;
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
  let userSA: SmartAccount;

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
    const expectedAccountAddress = await factory.getCounterFactualAddress(
      validatorModuleAddress, // validator address
      installData,
      saDeploymentIndex,
    );

    await factory.createAccount(validatorModuleAddress, installData, saDeploymentIndex);

    userSA = smartAccount.attach(expectedAccountAddress) as SmartAccount;
  });
 
  describe("Contract Deployment - Should not revert", function () {
    it("Should deploy smart account with createAccount", async function () {
      const saDeploymentIndex = 0;

      const installData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [ownerAddress],
      ); // Example data, customize as needed

      // Read the expected account address
      const expectedAccountAddress = await factory.getCounterFactualAddress(
        validatorModuleAddress, // validator address
        installData,
        saDeploymentIndex,
      );

      await factory.createAccount(
        validatorModuleAddress,
        installData,
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

      // Read the expected account address
      const expectedAccountAddress = await factory.getCounterFactualAddress(
        validatorModuleAddress, // validator address
        installData,
        saDeploymentIndex,
      );

      await factory.createAccount(
        validatorModuleAddress,
        installData,
        saDeploymentIndex,
      );

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy account with zero initialization data", async function () {
      const saDeploymentIndex = 25;

      const initializeData = smartAccount.interface.encodeFunctionData("initialize", [validatorModuleAddress, "0x"]);
      const initData = ethers.solidityPacked(["address", "uint256", "bytes"], [smartAccountAddress, 0, initializeData])

      // Read the expected account address
      const expectedAccountAddress = await factory.getCounterFactualAddress(
        validatorModuleAddress, // validator address
        initData,
        saDeploymentIndex,
      );

      await factory.createAccount(
        validatorModuleAddress,
        initData,
        saDeploymentIndex,
      );

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy account with invalid validation module", async function () {
      const saDeploymentIndex = 3;

      const initializeData = smartAccount.interface.encodeFunctionData("initialize", [ZeroAddress, ownerAddress.toString()]);
      const initData = ethers.solidityPacked(["address", "uint256", "bytes"], [smartAccountAddress, 0, initializeData])

      await expect(factory.createAccount(
        ZeroAddress,
        initData,
        saDeploymentIndex,
      )).to.be.reverted;
    });

    it("Should deploy smart account via handleOps", async function () {
        const saDeploymentIndex = 0;

        const installData = ethers.solidityPacked(["address"], [ownerAddress]); 
  
        const expectedAccountAddress = await factory.getCounterFactualAddress(
          validatorModuleAddress, 
          installData,
          saDeploymentIndex,
        );

        const initCode = factory.interface.encodeFunctionData("createAccount", [validatorModuleAddress, installData, saDeploymentIndex]);
  
        const userOp = buildPackedUserOp({
            sender: ownerAddress,
            initCode: initCode,
            callData: "0x",
        })

        const userOpNonce = await entryPoint.getNonce(
          expectedAccountAddress,
          ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
        );
        userOp.nonce = userOpNonce; 
    
        const userOpHash = await entryPoint.getUserOpHash(userOp);
        const userOpSignature = await owner.signMessage(ethers.getBytes(userOpHash));
        userOp.signature = userOpSignature;

        await entryPoint.depositTo(expectedAccountAddress, { value: to18(1) });
        await entryPoint.handleOps([userOp], bundlerAddress);
  
        // Verify that the account was created
        const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
        expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
      });

      it("Should prevent account reinitialization", async function () {
        const initData = smartAccount.interface.encodeFunctionData("initialize", [validatorModuleAddress, await owner.getAddress()]);
  
        const response = smartAccount.initialize(validatorModuleAddress, initData);
        await expect(response).to.be.revertedWithCustomError(smartAccount, "LinkedList_AlreadyInitialized()");
      });
  });
});
