import { ethers } from "hardhat";

async function main() {
  const Nexus = await ethers.getContractFactory("Nexus");

  const smartAccount = await Nexus.deploy();

  const signers = await ethers.getSigners();

  const factoryOwner = signers[0];

  await smartAccount.waitForDeployment();

  console.log(`Nexus implementation deployed at: ${smartAccount.target}`);

  const AccountFactoryGeneric = await ethers.getContractFactory("AccountFactoryGeneric");

  const accountFactory = await AccountFactoryGeneric.deploy(
    await smartAccount.getAddress(),
    await factoryOwner.getAddress()
  );

  await accountFactory.waitForDeployment();

  console.log(`AccountFactoryGeneric deployed at: ${accountFactory.target}`);

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
