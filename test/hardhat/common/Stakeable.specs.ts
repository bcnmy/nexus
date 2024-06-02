import { ethers } from "hardhat";
import { expect } from "chai";
import { AddressLike, parseEther } from "ethers";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { EntryPoint, Nexus, Stakeable } from "../../../typechain-types";
import { deployContractsAndSAFixture } from "../utils/deployment";
import { zeroAddress } from "viem";

describe("Stakeable tests", function () {
  let smartAccount: Nexus;
  let entryPoint: EntryPoint;
  let ownerAddress: AddressLike;
  let entryPointAddress: AddressLike;

  let stakeable: Stakeable;

  beforeEach(async function () {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    smartAccount = setup.deployedNexus;
    stakeable = setup.stakeable;
    ownerAddress = setup.accountOwner.address;
    entryPointAddress = await setup.entryPoint.getAddress();
  });

  describe("Stakeable basic tests", function () {
    it("Should correctly stake", async function () {
      const balanceBefore = await ethers.provider.getBalance(entryPointAddress);
      await stakeable.addStake(entryPointAddress, 60, {
        value: parseEther("1"),
      });
      const balanceAfter = await ethers.provider.getBalance(entryPointAddress);

      expect(balanceAfter - balanceBefore).to.eq(parseEther("1"));
    });

    it("Should fail to call addStake if not owner <= 0", async function () {
      const randomEOA = ethers.Wallet.createRandom(ethers.provider);
      await expect(
        stakeable
          .connect(randomEOA)
          .addStake(entryPointAddress, 0, { value: parseEther("1") }),
      ).to.be.reverted;
    });

    it("Should fail to call withdrawStake if not owner <= 0", async function () {
      const randomEOA = ethers.Wallet.createRandom(ethers.provider);
      await expect(
        stakeable
          .connect(randomEOA)
          .withdrawStake(entryPointAddress, ownerAddress),
      ).to.be.reverted;
    });

    it("Should fail to call unlockStake if not owner <= 0", async function () {
      const randomEOA = ethers.Wallet.createRandom(ethers.provider);
      await expect(stakeable.connect(randomEOA).unlockStake(entryPointAddress))
        .to.be.reverted;
    });

    it("Should fail to stake with a delay <= 0", async function () {
      await expect(
        stakeable.addStake(entryPointAddress, 0, { value: parseEther("1") }),
      ).to.be.revertedWith("must specify unstake delay");
    });

    it("Should fail to add stake to an incorrect entrypoint address", async function () {
      await expect(
        stakeable.addStake(zeroAddress, 0, { value: parseEther("1") }),
      ).to.be.revertedWith("Invalid EP address");
    });

    it("Should fail to unlock stake from an incorrect entrypoint address", async function () {
      await expect(stakeable.unlockStake(zeroAddress)).to.be.revertedWith(
        "Invalid EP address",
      );
    });

    it("Should fail to withdraw stake from an incorrect entrypoint address", async function () {
      await expect(
        stakeable.withdrawStake(zeroAddress, ownerAddress),
      ).to.be.revertedWith("Invalid EP address");
    });

    it("Should correctly unlock and withdraw", async function () {
      await stakeable.addStake(entryPointAddress, 1, {
        value: parseEther("1"),
      });

      await stakeable.unlockStake(entryPointAddress);

      const balanceBefore = await ethers.provider.getBalance(ownerAddress);
      await stakeable.withdrawStake(entryPointAddress, ownerAddress);
      const balanceAfter = await ethers.provider.getBalance(ownerAddress);

      expect(balanceAfter - balanceBefore).to.eq(parseEther("1"));
    });
  });
});
