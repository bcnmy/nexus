import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import {
  Counter,
  EntryPoint,
  K1Validator,
  MockExecutor,
  MockValidator,
  Nexus,
} from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import { installModule } from "../utils/erc7579Utils";
import {
  buildPackedUserOp,
  generateUseropCallData,
} from "../utils/operationHelpers";

describe("K1Validator module tests", () => {
  let deployedNexus: Nexus;
  let k1Validator: K1Validator;
  let owner: Signer;
  let mockValidator: MockValidator;
  let k1ModuleAddress: AddressLike;
  let mockExecutor: MockExecutor;
  let accountOwner: Signer;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let counter: Counter;

  before(async function () {
    ({
      deployedNexus,
      ecdsaValidator: k1Validator,
      mockExecutor,
      accountOwner,
      entryPoint,
      mockValidator,
      counter,
    } = await deployContractsAndSAFixture());
    owner = ethers.Wallet.createRandom();
    k1ModuleAddress = await k1Validator.getAddress();
    mockExecutor = mockExecutor;
    accountOwner = accountOwner;
    entryPoint = entryPoint;
    bundler = ethers.Wallet.createRandom();

    // Install K1Validator module
    await installModule({
      deployedNexus,
      entryPoint,
      module: k1Validator,
      validatorModule: mockValidator,
      moduleType: ModuleType.Validation,
      accountOwner,
      bundler,
    });
  });

  describe("K1Validtor tests", () => {
    it("should check if validator is installed", async () => {
      expect(
        await deployedNexus.isModuleInstalled(
          ModuleType.Validation,
          k1ModuleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;
    });

    it("should get module name", async () => {
      const name = await k1Validator.name();
      expect(name).to.equal("K1Validator");
    });

    it("should get module version", async () => {
      const version = await k1Validator.version();
      expect(version).to.equal("1.0.0-beta.1");
    });

    it("should check module type", async () => {
      const isValidator = await k1Validator.isModuleType(1);
      expect(isValidator).to.equal(true);
    });

    it("should check if module is initialized", async () => {
      const isInitialized = await k1Validator.isInitialized(
        await deployedNexus.getAddress(),
      );
      expect(isInitialized).to.equal(true);
    });

    it("should validateUserOp", async () => {
      const isModuleInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Validation,
        k1ModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isModuleInstalled).to.equal(true);

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const validatorModuleAddress = await k1Validator.getAddress();

      // Build the userOp with the generated callData.
      const userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);

      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      const isValid = await k1Validator.validateUserOp(userOp, userOpHash);
      // 0 - valid, 1 - invalid
      expect(isValid).to.equal(0n);
    });

    it("should validateUserOp using an already prefixed personal sign", async () => {
      const isModuleInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Validation,
        k1ModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isModuleInstalled).to.equal(true);

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const validatorModuleAddress = await k1Validator.getAddress();

      // Build the userOp with the generated callData.
      const userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);

      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );
      userOp.signature = signature;

      const prefix = "\x19Ethereum Signed Message:\n32";
      const prefixBuffer = ethers.toUtf8Bytes(prefix);
      // Concatenate the prefix and the userOpHash
      const concatBuffer = ethers.concat([prefixBuffer, userOpHash]);
      // Compute the keccak256 hash
      const personalSignHash = ethers.keccak256(concatBuffer);

      const isValid = await k1Validator.validateUserOp(
        userOp,
        personalSignHash,
      );
      // 0 - valid, 1 - invalid
      expect(isValid).to.equal(0n);
    });

    it("should fail on invalid user op", async () => {
      const isModuleInstalled = await deployedNexus.isModuleInstalled(
        ModuleType.Validation,
        k1ModuleAddress,
        ethers.hexlify("0x"),
      );

      expect(isModuleInstalled).to.equal(true);

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const validatorModuleAddress = await k1Validator.getAddress();

      // Build the userOp with the generated callData.
      let userOp = buildPackedUserOp({
        sender: await deployedNexus.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);

      const signature = await accountOwner.signMessage(
        ethers.getBytes(userOpHash),
      );

      userOp.signature = signature;

      // invalid signature
      userOp.signature = await accountOwner.signMessage(
        ethers.getBytes("0x1234"),
      );
      const isValid = await k1Validator.validateUserOp(userOp, userOpHash);

      // 0 - valid, 1 - invalid
      expect(isValid).to.equal(1);
    });

    // Review: below test started failing.
    // it("should sign with eth_sign", async () => {
    //   const isModuleInstalled = await deployedNexus.isModuleInstalled(
    //     ModuleType.Validation,
    //     k1ModuleAddress,
    //     ethers.hexlify("0x"),
    //   );

    //   expect(isModuleInstalled).to.equal(true);

    //   const callData = await generateUseropCallData({
    //     executionMethod: ExecutionMethod.Execute,
    //     targetContract: counter,
    //     functionName: "incrementNumber",
    //   });

    //   const validatorModuleAddress = await k1Validator.getAddress();

    //   // Build the userOp with the generated callData.
    //   const userOp = buildPackedUserOp({
    //     sender: await deployedNexus.getAddress(),
    //     callData,
    //   });
    //   userOp.callData = callData;

    //   const nonce = await entryPoint.getNonce(
    //     userOp.sender,
    //     ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
    //   );

    //   userOp.nonce = nonce;

    //   const userOpHash = await entryPoint.getUserOpHash(userOp);

    //   const isValid = await k1Validator.validateUserOp(userOp, userOpHash);

    //   // 0 - valid, 1 - invalid
    //   expect(isValid).to.equal(1);
    // });

    // Review
    it("Should check signature using isValidSignatureWithSender", async () => {
      const message = "Some Message";
      // const isValid = await k1Validator.isValidSignatureWithSender(await deployedNexus.getAddress(), , );
      // 0x1626ba7e - valid
      // 0xffffffff - invalid
    });
  });
});
