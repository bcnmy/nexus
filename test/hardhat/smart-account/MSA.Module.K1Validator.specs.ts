import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { Counter, EntryPoint, K1Validator, MockExecutor, MockValidator, SmartAccount } from "../../../typechain-types";
import { ExecutionMethod, ModuleType } from "../utils/types";
import {
  deployContractsAndSAFixture,
} from "../utils/deployment";
import { encodeData } from "../utils/encoding";
import { installModule } from "../utils/erc7579Utils";
import { buildPackedUserOp, generateUseropCallData } from "../utils/operationHelpers";

describe("K1Validator module tests", () => {
  
  let deployedMSA: SmartAccount;
  let k1Validator: K1Validator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let mockValidator: MockValidator;
  let k1ModuleAddress: AddressLike;
  let mockExecutor: MockExecutor;
  let accountOwner: Signer;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let counter: Counter;

  before(async function () {
    ({ deployedMSA, ecdsaValidator: k1Validator, mockExecutor, accountOwner, entryPoint, mockValidator, counter } =
      await deployContractsAndSAFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    k1ModuleAddress = await k1Validator.getAddress();
    mockExecutor = mockExecutor;
    accountOwner = accountOwner;
    entryPoint = entryPoint;
    bundler = ethers.Wallet.createRandom();

    // Install K1Validator module
    await installModule({ deployedMSA, entryPoint, moduleToInstall: k1Validator, validatorModule: mockValidator, moduleType: ModuleType.Validation, accountOwner, bundler })
  });

  describe("K1Validtor tests", () => {
    it("should check if validator is installed", async () => {
      expect(
        await deployedMSA.isModuleInstalled(
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
      expect(version).to.equal("0.0.1");
    });

    it("should check module type", async () => {
      const isValidator = await k1Validator.isModuleType(1);
      expect(isValidator).to.equal(true);
    });

    it("should get module types", async () => {
      const moduleTypes = await k1Validator.getModuleTypes();
      console.log("moduleTypes: ", moduleTypes);
      
      expect(moduleTypes).to.not.be.undefined;
    });

    it("should check user op using validateUserOp", async () => {
      const isModuleInstalled = await deployedMSA.isModuleInstalled(
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
        sender: await deployedMSA.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      console.log("userOpHash from hardhat: ", userOpHash);
      
      const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));

      userOp.signature = signature;

      const isValid = await k1Validator.validateUserOp(userOp, userOpHash);
      console.log("isValid: ", isValid.toString());
      
      // 0 - valid, 1 - invalid
      expect(isValid).to.equal(0n);
    });

    it("should check user op using isValidSignatureWithSender", async () => {
      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: counter,
        functionName: "incrementNumber",
      });

      const validatorModuleAddress = await k1Validator.getAddress();

      // Build the userOp with the generated callData.
      const userOp = buildPackedUserOp({
        sender: await deployedMSA.getAddress(),
        callData,
      });
      userOp.callData = callData;

      const nonce = await entryPoint.getNonce(
        userOp.sender,
        ethers.zeroPadBytes(validatorModuleAddress.toString(), 24),
      );

      userOp.nonce = nonce;

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));

      userOp.signature = signature;

      const isValid = await k1Validator.isValidSignatureWithSender(await deployedMSA.getAddress(), ethers.hashMessage(callData), callData);
      
      // 0 - valid, 1 - invalid
      expect(isValid.toString()).to.equal("0x1626ba7e");
    });
  });
});
