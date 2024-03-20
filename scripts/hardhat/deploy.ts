import { ethers } from "hardhat";

async function main() {
  const SmartAccount = await ethers.getContractFactory("SmartAccount");

  const smartAccount = await SmartAccount.deploy();

  await smartAccount.waitForDeployment();

  console.log(`SmartAccount deployed to: ${smartAccount.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().then(() => {
  process.exit(0);
})
.catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
