import { ethers } from "hardhat";
import { expect } from "chai";
import { Signer } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { buildUserOp, toBytes32 } from "./utils/utils";

async function deploySmartAccountFixture() {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const Entrypoint = await ethers.getContractFactory("EntryPoint");
  const entryPoint = await Entrypoint.deploy();
  await entryPoint.waitForDeployment();

  const SmartAccount = await ethers.getContractFactory("SmartAccount");
  const smartAccount = await SmartAccount.deploy();
  await smartAccount.waitForDeployment();

  return { entryPoint, smartAccount, accounts, addresses };
}

describe("SmartAccount Contract Tests", function () {
  let smartAccount: any;
  let entryPoint: any;
  let accounts: Signer[];
  let addresses: string[];

  before(async function () {
    const setup = await loadFixture(deploySmartAccountFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.smartAccount;
    accounts = setup.accounts;
    addresses = setup.addresses;
  });

  describe("Account Configuration", function () {
    it("Should return the correct account ID", async function () {
      expect(await smartAccount.accountId()).to.equal("ModularSmartAccount");
    });

    it("Should support specific execution modes", async function () {
      expect(await smartAccount.supportsAccountMode(toBytes32("0x01"))).to.be
        .true;
      expect(await smartAccount.supportsAccountMode(toBytes32("0xFF"))).to.be
        .true;
    });

    it("Should support specific module types", async function () {
      expect(await smartAccount.supportsModule(1)).to.be.true;
      expect(await smartAccount.supportsModule(99)).to.be.true;
    });
  });

  describe("Module Configuration", function () {
    let moduleAddress: string = ethers.hexlify(ethers.randomBytes(20));
    const moduleType = "1";

    it("Should allow installing a module", async function () {
      expect(
        await smartAccount.isModuleInstalled(
          moduleType,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;

      await smartAccount.installModule(
        moduleType,
        moduleAddress,
        ethers.hexlify("0x"),
      );

      expect(
        await smartAccount.isModuleInstalled(
          moduleType,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;
    });

    it("Should allow uninstalling a module", async function () {
      expect(
        await smartAccount.isModuleInstalled(
          moduleType,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      await smartAccount.uninstallModule(
        moduleType,
        moduleAddress,
        ethers.hexlify("0x"),
      );

      expect(
        await smartAccount.isModuleInstalled(
          moduleType,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;
    });
  });

  describe("Execution", function () {
    it("Should successfully call execute", async function () {
      const mode = toBytes32("0x01"); // Example mode
      const executionData = ethers.randomBytes(20); // Example execution data

      await expect(smartAccount.execute(mode, executionData)).to.not.be
        .reverted;
    });

    it("Should successfully call executeFromExecutor", async function () {
      const mode = toBytes32("0x01"); // Example mode
      const executionData = ethers.randomBytes(20); // Example execution data

      await expect(smartAccount.executeFromExecutor(mode, executionData)).to.not
        .be.reverted;
    });

    it("Should successfully call executeUserOp", async function () {
      // Construct a dummy user operation
      const userOp = {
        sender: await smartAccount.getAddress(),
        nonce: 0,
        initCode: "0x",
        callData: "0x",
        callGasLimit: 0,
        executionGasLimit: 0,
        verificationGasLimit: 0,
        preVerificationGas: 0,
        maxFeePerGas: 0,
        maxPriorityFeePerGas: 0,
        paymaster: ethers.ZeroAddress,
        paymasterData: "0x",
        signature: "0x",
      };

      const packedUserOp = buildUserOp(userOp);

      const userOpHash = ethers.keccak256(ethers.toUtf8Bytes("dummy"));

      await expect(smartAccount.executeUserOp(packedUserOp, userOpHash)).to.not
        .be.reverted;
    });
  });

  describe("Validation", function () {
    it("Should validate user operations correctly", async function () {
      const validUserOp = buildUserOp({
        sender: await smartAccount.getAddress(),
        nonce: 1,
        initCode: "0x",
        callData: "0x",
        callGasLimit: 400_000,
        executionGasLimit: 100_000,
        verificationGasLimit: 400_000,
        preVerificationGas: 150_000,
        maxFeePerGas: 100_000,
        maxPriorityFeePerGas: 100_000,
        paymaster: ethers.ZeroAddress,
        paymasterData: "0x",
        signature: "0x",
      });

      const userOpHash = await entryPoint.getUserOpHash(validUserOp);
      const tx = await smartAccount.validateUserOp(validUserOp, userOpHash, 0);
      const receipt = await tx.wait();
      expect(receipt.status).to.equal(1);
    });
  });
});
