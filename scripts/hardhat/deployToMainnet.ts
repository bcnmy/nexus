import { deployments, ethers } from "hardhat";
export const ENTRY_POINT_V7 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";

export async function deployToMainnet() {
  const accounts = await ethers.getSigners();
  const owner = accounts[0];
  const deployOptions = {
    from: await owner.getAddress(),
    deterministicDeployment: true,
  };

  const Nexus = await deployments.deploy("Nexus", {
    ...deployOptions,
    args: [ENTRY_POINT_V7],
  });
  const NexusBootstrap = await deployments.deploy("NexusBootstrap", deployOptions);
  const K1Validator = await deployments.deploy("K1Validator", deployOptions);
  const BootstrapLib = await deployments.deploy("BootstrapLib", deployOptions);
  const Registry = await deployments.deploy("MockRegistry", deployOptions);
  const K1ValidatorFactory = await deployments.deploy("K1ValidatorFactory", {
    ...deployOptions,
    args: [
      Nexus.address,
      deployOptions.from,
      K1Validator.address,
      NexusBootstrap.address,
      Registry.address,
    ],
    libraries: {
      BootstrapLib: BootstrapLib.address,
    },
  });
  const BiconomyMetaFactory = await deployments.deploy("BiconomyMetaFactory", {
    ...deployOptions,
    args: [deployOptions.from],
  });

  console.log(
    `BiconomyMetaFactory deployed at: ${BiconomyMetaFactory.address}`,
  );
  console.log(`K1ValidatorFactory deployed at: ${K1ValidatorFactory.address}`);
  console.log(`Registry deployed at: ${Registry.address}`);
  console.log(`BootstrapLib deployed at: ${BootstrapLib.address}`);
  console.log(`K1Validator deployed at: ${K1Validator.address}`);
  console.log(`NexusBootstrap deployed at: ${NexusBootstrap.address}`);
  console.log(`Nexus deployed at: ${Nexus.address}`);

  return {
    Nexus,
    NexusBootstrap,
    K1Validator,
    BootstrapLib,
    Registry,
    K1ValidatorFactory,
    BiconomyMetaFactory,
  };
}
