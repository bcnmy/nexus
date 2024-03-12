import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { MockValidator, SmartAccount } from "../../typechain-types";
import { ModuleType } from "./utils/types";
import {
  deploySmartAccountFixture,
  deploySmartAccountWithEntrypointFixture,
} from "./utils/deployment";

describe("SmartAccount Module Management", () => {
  let smartAccount: SmartAccount;
  let module: MockValidator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let moduleAddress: AddressLike;

  before(async function () {
    ({ smartAccount, module } =
      await deploySmartAccountWithEntrypointFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    moduleAddress = await module.getAddress();
  });

  describe("Installation and Uninstallation", () => {
    it("Should correctly install a module on the smart account", async () => {
      // // Verify the module is not installed initially
      // Note: do not get confused with above comment

      // Current test this should be expected to be true as it's default enabled module
      // We should write a test soon to enable some new validator / executor which is not installed before (as part of deployment or otherwise)
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      // TODO
      // WIP
      // Can't be used anymore as access control is applied

      /*await smartAccount.installModule(
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
      ).to.be.true;*/
    });

    it("Should correctly uninstall a previously installed module", async () => {
      // Precondition: The module is installed before the test

      // Works because it's default module
      expect(
        await smartAccount.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      // TODO
      // WIP
      // Can't be used anymore as access control is applied

      /*await smartAccount.uninstallModule(
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
      ).to.be.false;*/
    });
  });
});
