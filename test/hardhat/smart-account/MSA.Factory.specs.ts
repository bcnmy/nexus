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
 
  describe("Contract Deployment - Should not revert", function () {
    it("Should deploy smart account with createAccount", async function () {
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

      await factory.createAccount(
        moduleAddress,
        installData,
        saDeploymentIndex,
      );

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      console.log("proxy code ========= ", proxyCode);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });

    it("Should deploy smart account via handleOps", async function () {
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

        const initCode = factory.interface.encodeFunctionData("createAccount", [moduleAddress, installData, saDeploymentIndex]);
  
        const userOp = buildPackedUserOp({
            sender: ownerAddress,
            initCode: initCode,
            callData: "0x",
        })

        const userOpNonce = await entryPoint.getNonce(
            expectedAccountAddress,
            ethers.zeroPadBytes(moduleAddress.toString(), 24),
          );
          userOp.nonce = userOpNonce; 
    
        const userOpHash = await entryPoint.getUserOpHash(userOp);
        const userOpSignature = await owner.signMessage(ethers.getBytes(userOpHash));
        userOp.signature = userOpSignature;

        console.log("userOp ========= ", userOp);
        
        await entryPoint.handleOps([userOp], bundlerAddress);
  
        // Verify that the account was created
        const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
        console.log("proxy code ========= ", proxyCode);
        expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
      });
  });
});
