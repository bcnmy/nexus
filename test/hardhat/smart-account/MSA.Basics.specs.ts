import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer, concat, hashMessage, toBeHex, zeroPadBytes } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import { deployContractsAndSAFixture, deployContractsFixture } from "../utils/deployment";
import { encodeData, to18 } from "../utils/encoding";
import {
  getInitCode,
  buildPackedUserOp,
  generateUseropCallData,
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
  installModule,
} from "../utils/erc7579Utils";
import { zeroAddress } from "viem";

describe("SmartAccount Basic Specs", function () {
  let factory: AccountFactory;
  let smartAccount: SmartAccount;
  let entryPoint: EntryPoint;
  let accounts: Signer[];
  let addresses: string[] | AddressLike[];
  let factoryAddress: AddressLike;
  let entryPointAddress: AddressLike;
  let smartAccountAddress: AddressLike;
  let moduleAddress: AddressLike;
  let smartAccountOwner: Signer;
  let ownerAddress: AddressLike;
  let bundler: Signer;
  let bundlerAddress: AddressLike;
  let counter: Counter;
  let validatorModule: MockValidator;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.deployedMSA;
    factory = setup.msaFactory;
    accounts = setup.accounts;
    addresses = setup.addresses;
    counter = setup.counter;
    validatorModule = setup.mockValidator;
    smartAccountOwner = setup.accountOwner;

    entryPointAddress = await entryPoint.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    moduleAddress = await validatorModule.getAddress();
    factoryAddress = await factory.getAddress();
    ownerAddress = await smartAccountOwner.getAddress();
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
  });

  describe("Smart Account Basics", function () {
    it("Should correctly return the SmartAccount's ID", async function () {
      expect(await smartAccount.accountId()).to.equal(
        "biconomy.modular-smart-account.1.0.0-alpha",
      );
    });

    it("Should get implementation address of smart account", async () => {
      const saImplementation = await smartAccount.getImplementation();
      expect(saImplementation).to.not.equal(zeroAddress);
    })

    it("Should check deposit amount", async () => {
      await smartAccount.addDeposit({value: to18(1)});
      const deposit = await smartAccount.getDeposit();
      expect(deposit).to.be.greaterThan(0);
    })

    it("Should get entry point", async () => {
      const entryPointFromContract = await smartAccount.entryPoint();
      expect(entryPointFromContract).to.be.equal(entryPoint);
    })

    it("Should verify supported account modes", async function () {
      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;
      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;

      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_BATCH), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;

      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(EXECTYPE_TRY), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_BATCH), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;

      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(EXECTYPE_DELEGATE), 1),
            ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.false;
    });

    it("Should verify unsupported execution modes", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(await smartAccount.supportsExecutionMode(ethers.concat([
        ethers.zeroPadValue(toBeHex(EXECTYPE_DELEGATE), 1),
        ethers.zeroPadValue(toBeHex(CALLTYPE_SINGLE), 1),
        ethers.zeroPadValue(toBeHex(UNUSED), 4),
        ethers.zeroPadValue(toBeHex("0x00"), 4),
        ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
      ]))).to.be.false;
    });

    it("Should return false for unsupported execution mode", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      const mode = ethers.concat([CALLTYPE_SINGLE, "0x04", MODE_DEFAULT, UNUSED, MODE_PAYLOAD]);
      expect(await smartAccount.supportsExecutionMode(mode)).to.be.false;
    });

    it("Should confirm support for specified module types", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(await smartAccount.supportsModule(ModuleType.Validation)).to.be.true;
      expect(await smartAccount.supportsModule(ModuleType.Execution)).to.be.true;
    });

    it("Should withdraw deposit to owner address", async function () {
      const receiverAddress = ethers.Wallet.createRandom().address;

      await smartAccount.addDeposit({value: to18(1)});
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: smartAccount,
        functionName: "withdrawDepositTo",
        args: [receiverAddress, to18(1)]
      });
      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      const userOpNonce = await entryPoint.getNonce(
        smartAccountAddress,
        ethers.zeroPadBytes(moduleAddress.toString(), 24),
      );
      userOp.nonce = userOpNonce; 

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const userOpSignature = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));
      userOp.signature = userOpSignature;
      
      await entryPoint.handleOps([userOp], bundlerAddress);

      expect(await ethers.provider.getBalance(receiverAddress)).to.be.equal(to18(1));
    });

    it("Should revert with invalid validation module error", async function () {
      const randomAddress = "0x4f86BA17A9e82A8EeAB1dA2064f49E58FA9b5Dc0";
      const isModuleInstalled = await smartAccount.isModuleInstalled(
        ModuleType.Validation,
        randomAddress,
        ethers.hexlify("0x"),
      )
      expect(isModuleInstalled).to.be.false;
      const incrementNumber = counter.interface.encodeFunctionData("incrementNumber");
      const data = ethers.solidityPacked(["address", "uint256", "bytes"], [await counter.getAddress(), "0", incrementNumber]);
      const callData = encodeData(["bytes"], [data])
      const functionCalldata = concat([
        zeroPadBytes(randomAddress, 20), // Address needs to be 20 bytes, so pad it if necessary
        callData
      ]);
      await expect(smartAccount.isValidSignature(hashMessage(callData), functionCalldata)).to.be.rejected
    });

    it("Should check signature validity using smart account isValidSignature", async function () {
      const isModuleInstalled = await smartAccount.isModuleInstalled(
        ModuleType.Validation,
        await validatorModule.getAddress(),
        ethers.hexlify("0x"),
      )
      expect(isModuleInstalled).to.be.true;
      const message = "Some Message";
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

      const sig = await smartAccountOwner.signMessage(ethers.getBytes(userOpHash));

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
