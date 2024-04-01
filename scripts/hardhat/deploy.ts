import { ethers } from "hardhat";

async function main() {
  const SmartAccount = await ethers.getContractFactory("SmartAccount");

  const smartAccount = await SmartAccount.deploy();

  await smartAccount.waitForDeployment();

  console.log(
    `SmartAccount implementation deployed at: ${smartAccount.target}`,
  );

  const AccountFactory = await ethers.getContractFactory("AccountFactory");

  const accountFactory = await AccountFactory.deploy(
    await smartAccount.getAddress(),
  );

  await accountFactory.waitForDeployment();

  console.log(`AccountFactory deployed at: ${accountFactory.target}`);

  const K1Validator = await ethers.getContractFactory("K1Validator");

  const k1Validator = await K1Validator.deploy();

  await k1Validator.waitForDeployment();

  console.log(`K1Validator deployed at: ${k1Validator.target}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
