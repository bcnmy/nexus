import { ethers } from "hardhat";
import { getDeployedAccountK1Factory, getDeployedMetaFactory, getDeployedBootstrap, getDeployedBootstrapLib, getDeployedK1Validator, getDeployedMockExecutor, getDeployedNexusImplementation, getDeployedRegistry } from "../../test/hardhat/utils/deployment";

async function main() {
  const signers = await ethers.getSigners();
  const factoryOwner = signers[0];

  const nexus = await getDeployedNexusImplementation();
  await nexus.waitForDeployment();
  console.log(`Nexus implementation deployed at: ${nexus.target}`);

  const bootstrapper = await getDeployedBootstrap();
  await bootstrapper.waitForDeployment();
  console.log(`Bootstrapper deployed at: ${bootstrapper.target}`);

  const k1Validator = await getDeployedK1Validator();
  await k1Validator.waitForDeployment();
  console.log(`k1Validator deployed at: ${k1Validator.target}`);

  const bootstrapLib = await getDeployedBootstrapLib();
  await bootstrapLib.waitForDeployment();
  console.log(`BootstrapLib deployed at: ${bootstrapLib.target}`);

  const mockRegistry = await getDeployedRegistry();
  await mockRegistry.waitForDeployment();
  console.log(`Mock Registry deployed at: ${mockRegistry.target}`);

  const mockExecutor = await getDeployedMockExecutor();
  await mockExecutor.waitForDeployment();
  console.log(`Mock Executor deployed at: ${mockExecutor.target}`);

  const k1FactoryArgs = [
    await nexus.getAddress(),
    await factoryOwner.getAddress(),
    await k1Validator.getAddress(),
    await bootstrapper.getAddress(),
    await mockRegistry.getAddress(),
    await bootstrapLib.getAddress()
  ] as const;

  const k1ValidatorFactory = await getDeployedAccountK1Factory(...k1FactoryArgs);
  await k1ValidatorFactory.waitForDeployment();
  console.log(`k1ValidatorFactory deployed at: ${k1ValidatorFactory.target}`);

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
