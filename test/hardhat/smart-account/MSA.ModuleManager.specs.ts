import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { MockValidator, SmartAccount } from "../../../typechain-types";
import { ModuleType } from "../utils/types";
import {
  deployContractsFixture,
  deployContractsAndSAFixture,
} from "../utils/deployment";

describe("SmartAccount Module Management", () => {
  let deployedMSA: SmartAccount;
  let mockValidator: MockValidator;
  let owner: Signer;
  let ownerAddress: AddressLike;
  let moduleAddress: AddressLike;

  before(async function () {
    ({ deployedMSA, mockValidator } =
      await deployContractsAndSAFixture());
    owner = ethers.Wallet.createRandom();
    ownerAddress = await owner.getAddress();
    moduleAddress = await mockValidator.getAddress();
  });

  describe("Installation and Uninstallation", () => {
    it("Should correctly install a module on the smart account", async () => {
      // Current test this should be expected to be true as it's default enabled module
      expect(
        await deployedMSA.isModuleInstalled(
          ModuleType.Validation,
          moduleAddress,
          ethers.hexlify("0x"),
        ),
      ).to.be.true;

      // Todo:
      // Install module via userOp and confirm it's installed
    });

    it("Should correctly uninstall a previously installed module", async () => {
    });
  });
});
