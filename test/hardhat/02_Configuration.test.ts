import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, Signer } from "ethers";
import { MockValidator, SmartAccount } from "../../typechain-types";
import { ModuleType } from "./utils/types";
import { deploySmartAccountFixture } from "./utils/deployment";
import { toBytes32 } from "./utils/encoding";

describe("SmartAccount Configuration Tests", function () {
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

  describe("Account ID and Supported Modes", function () {
    it("Should correctly return the SmartAccount's ID", async function () {
      expect(await smartAccount.accountId()).to.equal(
        "biconomy.modular-smart-account.1.0.0-alpha",
      );
    });

    it("Should verify supported account modes", async function () {
      expect(await smartAccount.supportsExecutionMode(toBytes32("0x01"))).to.be
        .true;
      expect(await smartAccount.supportsExecutionMode(toBytes32("0xFF"))).to.be
        .true;
    });

    it("Should confirm support for specified module types", async function () {
      // Checks support for predefined module types (e.g., Validation, Execution)
      expect(await smartAccount.supportsModule(ModuleType.Validation)).to.be
        .true;
      expect(await smartAccount.supportsModule(ModuleType.Execution)).to.be
        .true;
      expect(await smartAccount.supportsModule(ModuleType.Hooks)).to.be.true;
      expect(await smartAccount.supportsModule(ModuleType.Fallback)).to.be.true;
    });
  });
});
