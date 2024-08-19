import { ethers } from "hardhat";
import { expect } from "chai";
import {
  AddressLike,
  Signer,
  ZeroAddress,
  keccak256,
  solidityPacked,
  toBeHex,
} from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  K1ValidatorFactory,
  Counter,
  EntryPoint,
  MockValidator,
  Nexus,
} from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import { to18 } from "../utils/encoding";
import {
  getInitCode,
  buildPackedUserOp,
  generateUseropCallData,
  getNonce,
  MODE_VALIDATION,
  getAccountDomainStructFields
} from "../utils/operationHelpers";
import {
  CALLTYPE_BATCH,
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  CALLTYPE_DELEGATE,
  EXECTYPE_TRY,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
} from "../utils/erc7579Utils";

describe("Nexus Basic Specs", function () {
  let factory: K1ValidatorFactory;
  let smartAccount: Nexus;
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
  let deployer: Signer;
  let aliceOwner: Signer;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.deployedNexus;
    factory = setup.nexusK1Factory;
    accounts = setup.accounts;
    addresses = setup.addresses;
    counter = setup.counter;
    validatorModule = setup.mockValidator;
    smartAccountOwner = setup.accountOwner;
    deployer = setup.deployer;
    aliceOwner = setup.aliceAccountOwner;

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
    const expectedAccountAddress = await factory.computeAccountAddress(
      accountOwnerAddress,
      saDeploymentIndex,
      [],
      0,
    );

    await factory.createAccount(accountOwnerAddress, saDeploymentIndex, [], 0);
  });

  describe("Contract Deployment", function () {
    it("Should deploy smart account", async function () {
      const saDeploymentIndex = 0;

      const installData = ethers.AbiCoder.defaultAbiCoder().encode(
        ["address"],
        [ownerAddress],
      ); // Example data, customize as needed

      // Read the expected account address
      const expectedAccountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      await factory.createAccount(ownerAddress, saDeploymentIndex, [], 0);

      // Verify that the account was created
      const proxyCode = await ethers.provider.getCode(expectedAccountAddress);
      expect(proxyCode).to.not.equal("0x", "Account should have bytecode");
    });
  });

  describe("Smart Account Basics", function () {
    it("Should correctly return the Nexus's ID", async function () {
      expect(await smartAccount.accountId()).to.equal(
        "biconomy.nexus.1.0.0-beta",
      );
    });

    it("Should get implementation address of smart account", async () => {
      const saImplementation = await smartAccount.getImplementation();
      expect(saImplementation).to.not.equal(ZeroAddress);
    });

    it("Should get smart account nonce", async () => {
      const nonce = await smartAccount.nonce(
        ethers.zeroPadBytes(moduleAddress.toString(), 24),
      );
      expect(nonce).to.be.greaterThanOrEqual(0);
    });

    it("Should check deposit amount", async () => {
      await smartAccount.addDeposit({ value: to18(1) });
      const deposit = await smartAccount.getDeposit();
      expect(deposit).to.be.greaterThan(0);
    });

    it("Should get entry point", async () => {
      const entryPointFromContract = await smartAccount.entryPoint();
      expect(entryPointFromContract).to.be.equal(entryPoint);
    });

    it("Should get domain separator", async () => {
      const domainSeparator = await smartAccount.DOMAIN_SEPARATOR();
      expect(domainSeparator).to.not.equal(ZeroAddress);
    });

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
            ethers.zeroPadValue(toBeHex(CALLTYPE_DELEGATE), 1),
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex(MODE_DEFAULT), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;
    });

    it("Should verify unsupported execution modes", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(
        await smartAccount.supportsExecutionMode(
          ethers.concat([
            ethers.zeroPadValue(toBeHex(CALLTYPE_DELEGATE), 1),
            ethers.zeroPadValue(toBeHex(EXECTYPE_DEFAULT), 1),
            ethers.zeroPadValue(toBeHex(UNUSED), 4),
            ethers.zeroPadValue(toBeHex("0x00"), 4),
            ethers.zeroPadValue(toBeHex(MODE_PAYLOAD), 22),
          ]),
        ),
      ).to.be.true;
    });

    it("Should return false for unsupported execution mode", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      const mode = ethers.concat([
        CALLTYPE_SINGLE,
        "0x04",
        MODE_DEFAULT,
        UNUSED,
        MODE_PAYLOAD,
      ]);
      expect(await smartAccount.supportsExecutionMode(mode)).to.be.false;
    });

    it("Should confirm support for specified module types", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(await smartAccount.supportsModule(ModuleType.Validation)).to.be
        .true;
      expect(await smartAccount.supportsModule(ModuleType.Execution)).to.be
        .true;
    });

    it("Should withdraw deposit to owner address", async function () {
      const receiverAddress = ethers.Wallet.createRandom().address;

      await smartAccount.addDeposit({ value: to18(1) });
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: smartAccount,
        functionName: "withdrawDepositTo",
        args: [receiverAddress, to18(1)],
      });
      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      const userOpNonce = await getNonce(
        entryPoint,
        smartAccountAddress,
        MODE_VALIDATION,
        moduleAddress.toString()
      );
      userOp.nonce = userOpNonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const userOpSignature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = userOpSignature;

      await entryPoint.handleOps([userOp], bundlerAddress);

      expect(await ethers.provider.getBalance(receiverAddress)).to.be.equal(
        to18(1),
      );
    });

    // References
    // https://pastebin.com/EVQxRH3n
    // https://viem.sh/docs/accounts/signTypedData#message
    // https://github.com/frangio/eip712-wrapper-for-eip1271/blob/master/src/eip1271-account.ts#L34
    // https://github.com/wevm/viem/blob/main/src/actions/wallet/signMessage.ts
    // https://github.com/ethers-io/ethers.js/blob/92761872198cf6c9334570da3d110bca2bafa641/src.ts/providers/provider-jsonrpc.ts#L435
    it("Should check signature validity using smart account isValidSignature for Personal Sign", async function () {
      const isModuleInstalled = await smartAccount.isModuleInstalled(
        ModuleType.Validation,
        await validatorModule.getAddress(),
        ethers.hexlify("0x"),
      );
      expect(isModuleInstalled).to.be.true;

      // 1. Convert foundry util to ts code (as below)

      const data = keccak256("0x1234");
      
      // Define constants as per the original Solidity function
      const PARENT_TYPEHASH = "PersonalSign(bytes prefixed)";

      // Calculate the domain separator
      const domainSeparator = await smartAccount.DOMAIN_SEPARATOR();

      // Calculate the parent struct hash
      const parentStructHash = ethers.keccak256(
        ethers.AbiCoder.defaultAbiCoder().encode(
          ["bytes32", "bytes32"],
          [ethers.keccak256(ethers.toUtf8Bytes(PARENT_TYPEHASH)), data],
        ),
      );

      // Calculate the final hash
      const resultHash = ethers.keccak256(
        ethers.concat(["0x1901", domainSeparator, parentStructHash]),
      );

      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(resultHash),
      );

      const isValid = await smartAccount.isValidSignature(
        data,
        solidityPacked(
          ["address", "bytes"],
          [await validatorModule.getAddress(), signature],
        ),
      );

      expect(isValid).to.equal("0x1626ba7e");
    });

    it("Should check signature validity using smart account isValidSignature for EIP 712 signature", async function () {
      const PARENT_TYPEHASH = "TypedDataSign(Contents contents,bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)Contents(bytes32 stuff)";
      const APP_DOMAIN_SEPARATOR = "0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b";
      const data = "0x1234";
      const contents = ethers.keccak256(ethers.toUtf8Bytes(data));

      const accountDomainStructFields = await getAccountDomainStructFields(smartAccount);
    
      const parentStructHash = ethers.keccak256(
        ethers.solidityPacked(["bytes", "bytes"],[
          ethers.AbiCoder.defaultAbiCoder().encode(
            ["bytes32", "bytes32"],
            [ethers.keccak256(ethers.toUtf8Bytes(PARENT_TYPEHASH)), contents]
          ),
          accountDomainStructFields
        ])
      );

      const dataToSign = ethers.keccak256(
        ethers.concat([
            '0x1901',
            APP_DOMAIN_SEPARATOR,
            parentStructHash
        ])
       );
    
      const signature = await smartAccountOwner.signMessage(ethers.getBytes(dataToSign));
    
      const contentsType = ethers.toUtf8Bytes("Contents(bytes32 stuff)");
      
      const signatureData = ethers.concat([
          signature,
          APP_DOMAIN_SEPARATOR,
          contents,
          contentsType,
          ethers.toBeHex(contentsType.length, 2) 
      ]);
      
      const contentsHash = keccak256(
        ethers.concat([
          '0x1901',
          APP_DOMAIN_SEPARATOR,
          contents
        ])
      );
    
      const finalSignature = ethers.solidityPacked(["address", "bytes"],[
        await validatorModule.getAddress(),
        signatureData
      ]);
    
      const isValid = await smartAccount.isValidSignature(contentsHash, finalSignature);
    
      expect(isValid).to.equal("0x1626ba7e");
    });
      
  });

  describe("Smart Account check Only Entrypoint actions", function () {
    it("Should revert with AccountAccessUnauthorized", async function () {
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const userOp = buildPackedUserOp({
        sender: await smartAccount.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const validatorModuleAddress = await validatorModule.getAddress();
      const nonce = await smartAccount.nonce(
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);

      const signature = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      await expect(
        smartAccount.validateUserOp(userOp, userOpHash, 0n),
      ).to.be.revertedWithCustomError(
        smartAccount,
        "AccountAccessUnauthorized",
      );
    });
  });

  describe("Nexus Smart Account Deployment via EntryPoint", function () {
    it("Should successfully deploy Smart Account via the EntryPoint", async function () {
      const saDeploymentIndex = 1;
      // This involves preparing a user operation (userOp), signing it, and submitting it through the EntryPoint
      const initCode = await getInitCode(
        ownerAddress,
        factoryAddress,
        saDeploymentIndex,
      );

      // Module initialization data, encoded
      const moduleInitData = ethers.solidityPacked(["address"], [ownerAddress]);

      const accountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      const nonce = await getNonce(
        entryPoint,
        accountAddress,
        MODE_VALIDATION,
        moduleAddress.toString()
      );

      const packedUserOp = buildPackedUserOp({
        sender: accountAddress,
        nonce,
        initCode,
      });

      const userOpHash = await entryPoint.getUserOpHash(packedUserOp);

      const sig = await smartAccountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      packedUserOp.signature = sig;

      await entryPoint.depositTo(accountAddress, { value: to18(1) });

      await entryPoint.handleOps([packedUserOp], bundlerAddress);
    });

    it("Should fail Smart Account deployment with an unauthorized signer", async function () {
      const saDeploymentIndex = 2;
      const initCode = await getInitCode(
        ownerAddress,
        factoryAddress,
        saDeploymentIndex,
      );
      // Module initialization data, encoded
      const moduleInitData = ethers.solidityPacked(["address"], [ownerAddress]);

      const accountAddress = await factory.computeAccountAddress(
        ownerAddress,
        saDeploymentIndex,
        [],
        0,
      );

      const nonce = await getNonce(
        entryPoint,
        accountAddress,
        MODE_VALIDATION,
        moduleAddress.toString()
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
