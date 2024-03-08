import { Signer } from "ethers";
import { deployments, ethers } from "hardhat";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  MockValidator,
  SmartAccount,
} from "../../../typechain-types";
import { DeploymentFixture, ModuleType } from "./types";
import {
  generateFullInitCode,
  getAccountAddress,
  signUserOperation,
} from "./operationHelpers";
import { to18 } from "./encoding";

/**
 * Generic function to deploy a contract using ethers.js.
 *
 * @param contractName The name of the contract to deploy.
 * @param deployer The Signer object representing the deployer account.
 * @returns A promise that resolves to the deployed contract instance.
 */
export async function deployContract<T>(
  contractName: string,
  deployer: Signer,
): Promise<T> {
  const ContractFactory = await ethers.getContractFactory(
    contractName,
    deployer,
  );
  const contract = await ContractFactory.deploy();
  await contract.waitForDeployment();
  return contract as T;
}

/**
 * Deploys the EntryPoint contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed EntryPoint contract instance.
 */
export async function deployEntrypoint(): Promise<EntryPoint> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const Entrypoint = await ethers.getContractFactory("EntryPoint");
  const deterministicEntryPoint = await deployments.deploy("EntryPoint", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return Entrypoint.attach(deterministicEntryPoint.address) as EntryPoint;
}

/**
 * Deploys the smart contract infrastructure required for testing.
 * This includes the EntryPoint, SmartAccount, AccountFactory, MockValidator, and Counter contracts.
 *
 * @returns A promise that resolves to a DeploymentFixture object containing deployed contracts and account information.
 */
export async function deploySmartAccountFixture(): Promise<DeploymentFixture> {
  const [deployer, ...accounts] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const entryPoint = await deployEntrypoint();
  const smartAccount = await deployContract<SmartAccount>(
    "SmartAccount",
    deployer,
  );
  const factory = await deployContract<AccountFactory>(
    "AccountFactory",
    deployer,
  );
  const module = await deployContract<MockValidator>("MockValidator", deployer);
  const counter = await deployContract<Counter>("Counter", deployer);

  return {
    entryPoint,
    smartAccount,
    factory,
    module,
    counter,
    accounts,
    addresses,
  };
}

/**
 * Deploys the smart contract infrastructure with a smart account through the entry point.
 * This setup is designed to prepare a testing environment for smart account operations.
 *
 * @returns The deployment fixture including deployed contracts and the smart account owner.
 */
export async function deploySmartAccountWithEntrypointFixture(): Promise<any> {
  const owner = ethers.Wallet.createRandom();
  const [deployer, ...accounts] = await ethers.getSigners();

  const entryPoint = await deployEntrypoint();
  const smartAccountFactory = await ethers.getContractFactory("SmartAccount");
  const module = await deployContract<MockValidator>("MockValidator", deployer);
  const factory = await deployContract<AccountFactory>(
    "AccountFactory",
    deployer,
  );
  const counter = await deployContract<Counter>("Counter", deployer);

  // Get the addresses of the deployed contracts
  const factoryAddress = await factory.getAddress();
  const moduleAddress = await module.getAddress();
  const ownerAddress = await owner.getAddress();

  // Generate the initialization code for the smart account
  const initCode = await generateFullInitCode(
    ownerAddress,
    factoryAddress,
    moduleAddress,
    ModuleType.Validation,
  );

  // Get the counterfactual address of the smart account before deployment
  const accountAddress = await getAccountAddress(
    ownerAddress,
    factoryAddress,
    moduleAddress,
    ModuleType.Validation,
  );

  // Sign the user operation for deploying the smart account
  const packedUserOp = await signUserOperation(
    accountAddress,
    initCode,
    entryPoint,
    moduleAddress,
    owner,
  );

  // Deposit ETH to the smart account
  await entryPoint.depositTo(accountAddress, { value: to18(1) });

  // Handle the user operation to deploy the smart account
  await entryPoint.handleOps([packedUserOp], ownerAddress);

  // Attach the SmartAccount contract to the deployed address
  const smartAccount = smartAccountFactory.attach(accountAddress);

  // Get the addresses of the other accounts
  const addresses = await Promise.all(
    accounts.map(async (acc) => await acc.getAddress()),
  );

  return {
    entryPoint,
    smartAccount,
    factory,
    module,
    counter,
    owner,
    addresses,
  };
}
