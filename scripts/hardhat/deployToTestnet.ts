import { deployments, ethers } from "hardhat";
import { deployToMainnet } from "./deployToMainnet";

export async function deployToTestnet() {
  const { Nexus } = await deployToMainnet();

  const accounts = await ethers.getSigners();
  const owner = accounts[0];
  const deployOptions = {
    from: await owner.getAddress(),
    deterministicDeployment: true,
  };

  const MockValidator = await deployments.deploy(
    "MockValidator",
    deployOptions,
  );
  const MockHook = await deployments.deploy("MockHook", deployOptions);
  const MockHandler = await deployments.deploy("MockHandler", deployOptions);
  const MockExecutor = await deployments.deploy("MockExecutor", deployOptions);
  const TokenWithPermit = await deployments.deploy("TokenWithPermit", {
    ...deployOptions,
    args: ["MockPermitToken", "MPT"],
  });
  const MockToken = await deployments.deploy("MockToken", {
    ...deployOptions,
    args: ["Test Token", "TST"],
  });
  const MockCounter = await deployments.deploy("Counter", deployOptions);
  const Stakeable = await deployments.deploy("Stakeable", {
    ...deployOptions,
    args: [deployOptions.from],
  });
  const NexusAccountFactory = await deployments.deploy("NexusAccountFactory", {
    ...deployOptions,
    args: [Nexus.address, deployOptions.from],
  });

  console.log(
    `NexusAccountFactory deployed at: ${NexusAccountFactory.address}`,
  );
  console.log(`Stakeable deployed at: ${Stakeable.address}`);
  console.log(`Counter deployed at: ${MockCounter.address}`);
  console.log(`MockToken deployed at: ${MockToken.address}`);
  console.log(`MockExecutor deployed at: ${MockExecutor.address}`);
  console.log(`TokenWithPermit deployed at: ${TokenWithPermit.address}`);
  console.log(`MockHandler deployed at: ${MockHandler.address}`);
  console.log(`MockHook deployed at: ${MockHook.address}`);
  console.log(`MockValidator deployed at: ${MockValidator.address}`);
}
