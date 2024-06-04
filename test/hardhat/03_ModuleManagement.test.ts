import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { MockValidator, SmartAccount } from "../../typechain-types";
import { ModuleType } from "./utils/types";
import { deploySmartAccountFixture } from "./utils/deployment";

describe("SmartAccount Module Management", () => {
  let smartAccount: SmartAccount;
  let module: MockValidator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let moduleAddress: AddressLike;

  before(async function () {
    ({ smartAccount, module } = await deploySmartAccountFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    moduleAddress = await module.getAddress();
  });

  describe("Installation and Uninstallation", () => {
    it("Should correctly install a module on the smart account", async () => {
      // Verify the module is not installed initially
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;

      await smartAccount.installModule(
        ModuleType.Validation,
        moduleAddress,
        ethers.hexlify("0x"),
      );

      // Verify the module is installed after the installation
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;
    });

    it("Should correctly uninstall a previously installed module", async () => {
      // Precondition: The module is installed before the test
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      await smartAccount.uninstallModule(
        ModuleType.Validation,
        moduleAddress,
        ethers.hexlify("0x"),
      );

      // Verify the module is no longer installed
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.false;
    });
  });
});
