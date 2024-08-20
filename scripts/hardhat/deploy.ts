import { ethers } from "hardhat";
import fs from "node:fs";
import path from "node:path";

async function main() {
  const ENTRY_POINT_V7 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";

  const Nexus = await ethers.getContractFactory("Nexus");

  const smartAccountImpl = await Nexus.deploy(ENTRY_POINT_V7);

  const signers = await ethers.getSigners();

  const factoryOwner = signers[0];

  await smartAccountImpl.waitForDeployment();

  console.log(`Nexus implementation deployed at: ${smartAccountImpl.target}`);

  const Bootstrapper = await ethers.getContractFactory("Bootstrap");

  const bootstrapper = await Bootstrapper.deploy();

  await bootstrapper.waitForDeployment();

  console.log(`Bootstrapper deployed at: ${bootstrapper.target}`);

  const K1Validator = await ethers.getContractFactory("K1Validator");

  const k1Validator = await K1Validator.deploy();

  await k1Validator.waitForDeployment();

  console.log(`K1Validator deployed at: ${k1Validator.target}`);

  const BootstrapLib = await ethers.getContractFactory("BootstrapLib");

  const bootstrapLib = await BootstrapLib.deploy();

  await bootstrapLib.waitForDeployment();

  console.log(`BootstrapLib deployed at: ${bootstrapLib.target}`);

  const K1ValidatorFactory = await ethers.getContractFactory(
    "K1ValidatorFactory",
    {
      libraries: {
        BootstrapLib: await bootstrapLib.getAddress(),
      },
    },
  );

  const MockRegistry = await ethers.getContractFactory("MockRegistry");

  const mockRegistry = await MockRegistry.deploy();

  await mockRegistry.waitForDeployment();

  const k1ValidatorFactory = await K1ValidatorFactory.deploy(
    await smartAccountImpl.getAddress(),
    await factoryOwner.getAddress(),
    await k1Validator.getAddress(),
    await bootstrapper.getAddress(),
    await mockRegistry.getAddress()
  );


  await k1ValidatorFactory.waitForDeployment();

  console.log(`k1ValidatorFactory deployed at: ${k1ValidatorFactory.target}`);

  const BiconomyMetaFactory = await ethers.getContractFactory(
    "BiconomyMetaFactory",
  );

  const biconomyMetaFactory = await BiconomyMetaFactory.deploy(
    await factoryOwner.getAddress(),
  );

  await biconomyMetaFactory.waitForDeployment();

  console.log(`BiconomyMetaFactory deployed at: ${biconomyMetaFactory.target}`);

  const deployedContracts = { 
    Nexus: {
      path: "contracts/Nexus.sol/Nexus.json",
      address: smartAccountImpl.target.toString(),
      name: "Nexus",
    },
    Bootstrap: {
      path: "contracts/utils/RegistryBootstrap.sol/Bootstrap.json",
      address: bootstrapper.target.toString(),
      name: "Bootstrap",
    },
    K1Validator: {
      path: "contracts/modules/validators/K1Validator.sol/K1Validator.json",
      address: k1Validator.target.toString(),
      name: "K1Validator",
    },
    BootstrapLib: {
      path: "contracts/lib/BootstrapLib.sol/BootstrapLib.json",
      address: bootstrapLib.target.toString(),
      name: "BootstrapLib",
    },
    K1ValidatorFactory: {
      path: "contracts/factory/K1ValidatorFactory.sol/K1ValidatorFactory.json",
      address: k1ValidatorFactory.target.toString(),
      name: "K1ValidatorFactory",
    },
    BiconomyMetaFactory: {
      path: "contracts/factory/BiconomyMetaFactory.sol/BiconomyMetaFactory.json",
      address: biconomyMetaFactory.target.toString(),
      name: "BiconomyMetaFactory",
    },
  };

  for (const contract in deployedContracts) {
    const artifact = require(path.resolve(__dirname, "../../artifacts/", deployedContracts[contract].path));
    deployedContracts[contract].abi = artifact.abi;
    deployedContracts[contract].bytecode = artifact.bytecode;
  }

  // Write to artifacts
  fs.writeFileSync(
    __dirname + "/../../hh-deployed-contracts.json",
    JSON.stringify(deployedContracts, null, 2),
  );

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
