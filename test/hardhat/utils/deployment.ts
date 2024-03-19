import { BytesLike, HDNodeWallet, Signer } from "ethers";
import { deployments, ethers } from "hardhat";
import {
  AccountFactory,
  Counter,
  EntryPoint,
  EntryPoint__factory,
  MockExecutor,
  MockHandler,
  MockHook,
  MockToken,
  MockValidator,
  R1Validator,
  SmartAccount,
} from "../../../typechain-types";
import { DeploymentFixture, DeploymentFixtureWithSA, ModuleType } from "./types";
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
export async function getDeployedEntrypoint(): Promise<EntryPoint> {
  const [deployer, ...accounts] = await ethers.getSigners();

  // Note: There should be a way to cache deployed addresses 

  // const EntryPointDeployment = await deployments.get("EntryPoint");
  // if(EntryPointDeployment) {
  //   return EntryPoint__factory.connect(
  //     EntryPointDeployment.address,
  //     deployer
  //   );
  // }

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
 * Deploys the AccountFactory contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed EntryPoint contract instance.
 */
export async function getDeployedAccountFactory(
  implementationAddress: string,
  // Note: this could be converted to dto so that additional args can easily be passed
): Promise<AccountFactory> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const AccountFactory = await ethers.getContractFactory("AccountFactory");
  const deterministicAccountFactory = await deployments.deploy(
    "AccountFactory",
    {
      from: addresses[0],
      deterministicDeployment: true,
      args: [implementationAddress],
    },
  );

  return AccountFactory.attach(
    deterministicAccountFactory.address,
  ) as AccountFactory;
}

/**
 * Deploys the Counter contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed Counter contract instance.
 */
export async function getDeployedCounter(): Promise<Counter> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const Counter = await ethers.getContractFactory("Counter");
  const deterministicCounter = await deployments.deploy("Counter", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return Counter.attach(deterministicCounter.address) as Counter;
}

/**
 * Deploys the ERC20 MockToken contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed MockToken contract instance.
 */
export async function getDeployedMockToken(): Promise<MockToken> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const MockToken = await ethers.getContractFactory("MockToken");
  const deterministicMockToken = await deployments.deploy("MockToken", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return MockToken.attach(deterministicMockToken.address) as MockToken;
}

/**
 * Deploys the MockExecutor contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed MockExecutor contract instance.
 */
export async function getDeployedMockExecutor(): Promise<MockExecutor> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const MockExecutor = await ethers.getContractFactory("MockExecutor");
  const deterministicMockExecutor = await deployments.deploy("MockExecutor", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return MockExecutor.attach(deterministicMockExecutor.address) as MockExecutor;
}

/**
 * Deploys the MockValidator contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed MockValidator contract instance.
 */
export async function getDeployedMockValidator(): Promise<MockValidator> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const MockValidator = await ethers.getContractFactory("MockValidator");
  const deterministicMockValidator = await deployments.deploy("MockValidator", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return MockValidator.attach(deterministicMockValidator.address) as MockValidator;
}

/**
 * Deploys the MockHook contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed MockHook contract instance.
 */
export async function getDeployedMockHook(): Promise<MockHook> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const MockHook = await ethers.getContractFactory("MockHook");
  const deterministicMockHook = await deployments.deploy("MockHook", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return MockHook.attach(deterministicMockHook.address) as MockHook;
}

/**
 * Deploys the MockHandler contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed MockHandler contract instance.
 */
export async function getDeployedMockHandler(): Promise<MockHandler> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const MockHandler = await ethers.getContractFactory("MockHandler");
  const deterministicMockHandler = await deployments.deploy("MockHandler", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return MockHandler.attach(deterministicMockHandler.address) as MockHandler;
}

/**
 * Deploys the ECDSA R1Validator contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed ECDSA R1Validator contract instance.
 */
export async function getDeployedR1Validator(): Promise<R1Validator> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const R1Validator = await ethers.getContractFactory("R1Validator");
  const deterministicR1Validator = await deployments.deploy("R1Validator", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return R1Validator.attach(deterministicR1Validator.address) as R1Validator;
}

/**
 * Deploys the (MSA) Smart Account implementation contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed SA implementation contract instance.
 */
export async function getDeployedMSAImplementation(): Promise<SmartAccount> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const SmartAccount = await ethers.getContractFactory("SmartAccount");
  const deterministicMSAImpl = await deployments.deploy("SmartAccount", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return SmartAccount.attach(deterministicMSAImpl.address) as SmartAccount;
}

/**
 * Deploys the smart contract infrastructure required for testing.
 * This includes the all the required contracts for tests to run.
 *
 * @returns A promise that resolves to a DeploymentFixture object containing deployed contracts and account information.
 * @notice This function will not deploy a Smart Account proxy
 */
export async function deployContractsFixture(): Promise<DeploymentFixture> {
  const [deployer, ...accounts] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const entryPoint = await getDeployedEntrypoint();

  // Below both ways are fine
  /*const smartAccountImplementation = await deployContract<SmartAccount>(
    "SmartAccount",
    deployer,
  );*/
  const smartAccountImplementation = await getDeployedMSAImplementation();

  const msaFactory = await getDeployedAccountFactory(await smartAccountImplementation.getAddress());

  const mockValidator = await deployContract<MockValidator>("MockValidator", deployer);

  const ecdsaValidator = await getDeployedR1Validator();

  const mockToken = await getDeployedMockToken();

  const counter = await deployContract<Counter>("Counter", deployer);

  return {
    entryPoint,
    smartAccountImplementation,
    msaFactory,
    mockValidator,
    ecdsaValidator,
    counter,
    mockToken,
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
export async function deployContractsAndSAFixture(): Promise<DeploymentFixtureWithSA> {
  const saDeploymentIndex = 0;
  // Review: Should not be random
  const owner = ethers.Wallet.createRandom();
  const [deployer, ...accounts] = await ethers.getSigners();

  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const entryPoint = await getDeployedEntrypoint();

  const smartAccountImplementation = await getDeployedMSAImplementation();

  const msaFactory = await getDeployedAccountFactory(await smartAccountImplementation.getAddress());

  const mockValidator = await deployContract<MockValidator>("MockValidator", deployer);

  const ecdsaValidator = await getDeployedR1Validator();

  const mockToken = await getDeployedMockToken();

  const counter = await deployContract<Counter>("Counter", deployer);

  // Get the addresses of the deployed contracts
  const factoryAddress = await msaFactory.getAddress();
  const mockValidatorAddress = await mockValidator.getAddress();
  const r1ValidatorAddress = await ecdsaValidator.getAddress();
  const ownerAddress = await owner.getAddress();

  // Module initialization data, encoded
  const moduleInstallData = ethers.solidityPacked(["address"], [ownerAddress]);

  const accountAddress = await msaFactory.getCounterFactualAddress(
    mockValidatorAddress,
    moduleInstallData,
    saDeploymentIndex,
  );

  // deploy SA
  await msaFactory.createAccount(
    mockValidatorAddress,
    moduleInstallData,
    saDeploymentIndex);

  // Deposit ETH to the smart account
  await entryPoint.depositTo(accountAddress, { value: to18(1) });

  await mockToken.mint(accountAddress, to18(100));

  const SmartAccount = await ethers.getContractFactory("SmartAccount");

  // Attach the SmartAccount contract to the deployed address
  const deployedMSA = SmartAccount.attach(accountAddress) as SmartAccount;

  return {
    entryPoint,
    smartAccountImplementation,
    deployedMSA,
    accountOwner: owner,
    msaFactory,
    mockValidator,
    ecdsaValidator,
    counter,
    mockToken,
    accounts,
    addresses,
  };
}

// WIP
// Purpose is to serve deployed SA address (directly via factory)
// using already deployed addresses - EP, factory, implementation, validator/s (plus executors etc if factory supports more bootstrap config)
export async function getSmartAccountWithValidator(
  validatorAddress: string,
  onInstallData: BytesLike,
  index: number
) : Promise<SmartAccount>{
  return null;
};

// WIP
// TODO make this more dynamic, think of renaming
// Currently factory requires single validator and onInstallData for it
// but in future it could be array of validators and other kinds of modules as part of bootstrap config
// Also, it could be more generic to support different kinds of validators
// if onInstallData is provided, install given validator with given data (signer would become optional in this case)
// otherwise assume R1Validator, extract owner address from signer and generate onInstallData
// Note: it requires contracts to be passed as well because we need same instaces, entire setup object could be passed.
// Review/Todo: make a DTO and make some params optional and have conditional paths 
// If I want to do something using same contracts, I have to write logic in tests before hook itself and use utils from operation helpers
export async function getDeployedSmartAccountWithValidator(
  entryPoint: EntryPoint,
  mockToken: MockToken,
  signer: HDNodeWallet,
  accountFactory: AccountFactory,
  validatorAddress: string,
  onInstallData: BytesLike,
  deploymentIndex: number = 0,
): Promise<SmartAccount> {

  const ownerAddress = await signer.getAddress();
  // Module initialization data, encoded
  const moduleInstallData = ethers.solidityPacked(["address"], [ownerAddress]);

  const accountAddress = await accountFactory.getCounterFactualAddress(
    validatorAddress,
    moduleInstallData,
    deploymentIndex,
  );

  await entryPoint.depositTo(accountAddress, { value: to18(1) });

  await mockToken.mint(accountAddress, to18(100));

  await accountFactory.createAccount(
    validatorAddress,
    moduleInstallData,
    deploymentIndex);

  const SmartAccount = await ethers.getContractFactory("SmartAccount");

  // Attach the SmartAccount contract to the deployed address
  const deployedMSA = SmartAccount.attach(accountAddress) as SmartAccount;

  return deployedMSA;
}