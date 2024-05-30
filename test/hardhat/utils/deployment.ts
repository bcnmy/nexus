import { BytesLike, HDNodeWallet, Signer } from "ethers";
import { deployments, ethers } from "hardhat";
import {
  K1ValidatorFactory,
  Counter,
  EntryPoint,
  MockExecutor,
  MockHandler,
  MockHook,
  MockToken,
  MockValidator,
  K1Validator,
  Nexus,
  Bootstrap,
} from "../../../typechain-types";
import { DeploymentFixture, DeploymentFixtureWithSA } from "./types";
import { to18 } from "./encoding";

export const ENTRY_POINT_V7 = "0x0000000071727De22E5E9d8BAf0edAc6f37da032";

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
async function getDeployedEntrypoint() {

  // Deploy the contract normally to get its bytecode
  const Contract = await ethers.getContractFactory("EntryPoint");
  const contract = await Contract.deploy();
  await contract.waitForDeployment();

  // Retrieve the deployed contract bytecode
  const deployedCode = await ethers.provider.getCode(
    await contract.getAddress(),
  );

  // Use hardhat_setCode to set the contract code at the specified address
  await ethers.provider.send("hardhat_setCode", [ENTRY_POINT_V7, deployedCode]);

  return Contract.attach(ENTRY_POINT_V7) as EntryPoint;
}

/**
 * Deploys the K1ValidatorFactory contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed EntryPoint contract instance.
 */
export async function getDeployedAccountFactory(
  implementationAddress: string,
  owner: string,
  k1Validator: string,
  bootstrapper: string,
  // Note: this could be converted to dto so that additional args can easily be passed
): Promise<K1ValidatorFactory> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const K1ValidatorFactory =
    await ethers.getContractFactory("K1ValidatorFactory");
  const deterministicAccountFactory = await deployments.deploy(
    "K1ValidatorFactory",
    {
      from: addresses[0],
      deterministicDeployment: true,
      args: [owner, implementationAddress, k1Validator, bootstrapper],
    },
  );

  return K1ValidatorFactory.attach(
    deterministicAccountFactory.address,
  ) as K1ValidatorFactory;
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
    args: ["Test Token", "TST"],
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

  return MockValidator.attach(
    deterministicMockValidator.address,
  ) as MockValidator;
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
 * Deploys the ECDSA K1Validator contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed ECDSA K1Validator contract instance.
 */
export async function getDeployedK1Validator(): Promise<K1Validator> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const K1Validator = await ethers.getContractFactory("K1Validator");
  const deterministicK1Validator = await deployments.deploy("K1Validator", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return K1Validator.attach(deterministicK1Validator.address) as K1Validator;
}

/**
 * Deploys the (Nexus) Smart Account implementation contract with a deterministic deployment.
 * @returns A promise that resolves to the deployed SA implementation contract instance.
 */
export async function getDeployedNexusImplementation(): Promise<Nexus> {
  const accounts: Signer[] = await ethers.getSigners();
  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const Nexus = await ethers.getContractFactory("Nexus");
  const deterministicNexusImpl = await deployments.deploy("Nexus", {
    from: addresses[0],
    deterministicDeployment: true,
  });

  return Nexus.attach(deterministicNexusImpl.address) as Nexus;
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

  const factoryOwner = addresses[5];

  const entryPoint = await getDeployedEntrypoint();

  const smartAccountImplementation = await getDeployedNexusImplementation();

  const mockValidator = await deployContract<MockValidator>(
    "MockValidator",
    deployer,
  );

  const bootstrap = await deployContract<Bootstrap>("Bootstrap", deployer);

  const msaFactory = await getDeployedAccountFactory(
    await smartAccountImplementation.getAddress(),
    factoryOwner,
    await mockValidator.getAddress(),
    await bootstrap.getAddress(),
  );

  const ecdsaValidator = await getDeployedK1Validator();

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
  const [deployer, ...accounts] = await ethers.getSigners();
  const owner = accounts[1];
  const alice = accounts[2];

  const addresses = await Promise.all(
    accounts.map((account) => account.getAddress()),
  );

  const factoryOwner = addresses[5];

  const entryPoint = await getDeployedEntrypoint();

  const smartAccountImplementation = await getDeployedNexusImplementation();

  const mockValidator = await deployContract<MockValidator>(
    "MockValidator",
    deployer,
  );

  const bootstrap = await deployContract<Bootstrap>("Bootstrap", deployer);

  const msaFactory = await getDeployedAccountFactory(
    await smartAccountImplementation.getAddress(),
    factoryOwner,
    await mockValidator.getAddress(),
    await bootstrap.getAddress(),
  );

  const mockHook = await getDeployedMockHook();

  const mockHook2 = await deployContract<MockHook>(
    "MockHook",
    deployer,
  );

  const mockFallbackHandler = await getDeployedMockHandler();

  const mockExecutor = await getDeployedMockExecutor();

  const ecdsaValidator = await getDeployedK1Validator();

  const mockToken = await getDeployedMockToken();

  const counter = await deployContract<Counter>("Counter", deployer);

  // Get the addresses of the deployed contracts
  const ownerAddress = await owner.getAddress();
  const aliceAddress = await alice.getAddress();

  const accountAddress = await msaFactory.computeAccountAddress(
    ownerAddress,
    saDeploymentIndex,
  );

  const aliceAccountAddress = await msaFactory.computeAccountAddress(
    aliceAddress,
    saDeploymentIndex,
  );

  // deploy SA
  await msaFactory.createAccount(ownerAddress, saDeploymentIndex);

  await msaFactory.createAccount(aliceAddress, saDeploymentIndex);

  // Deposit ETH to the smart account
  await entryPoint.depositTo(accountAddress, { value: to18(1) });
  await entryPoint.depositTo(aliceAccountAddress, { value: to18(1) });

  await mockToken.mint(accountAddress, to18(100));

  const Nexus = await ethers.getContractFactory("Nexus");

  // Attach the Nexus contract to the deployed address
  const deployedNexus = Nexus.attach(accountAddress) as Nexus;
  const aliceDeployedNexus = Nexus.attach(aliceAccountAddress) as Nexus;

  return {
    entryPoint,
    smartAccountImplementation,
    deployedNexus,
    aliceDeployedNexus,
    deployedNexusAddress: accountAddress,
    accountOwner: owner,
    aliceAccountOwner: alice,
    deployer: deployer,
    msaFactory,
    mockValidator,
    mockExecutor,
    mockHook,
    mockHook2,
    mockFallbackHandler,
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
  index: number,
): Promise<Nexus> {
  return null;
}

// WIP
// TODO make this more dynamic, think of renaming
// Currently factory requires single validator and onInstallData for it
// but in future it could be array of validators and other kinds of modules as part of bootstrap config
// Also, it could be more generic to support different kinds of validators
// if onInstallData is provided, install given validator with given data (signer would become optional in this case)
// otherwise assume K1Validator, extract owner address from signer and generate onInstallData
// Note: it requires contracts to be passed as well because we need same instaces, entire setup object could be passed.
// Review/Todo: make a DTO and make some params optional and have conditional paths
// If I want to do something using same contracts, I have to write logic in tests before hook itself and use utils from operation helpers
export async function getDeployedSmartAccountWithValidator(
  entryPoint: EntryPoint,
  mockToken: MockToken,
  signer: HDNodeWallet,
  accountFactory: K1ValidatorFactory,
  validatorAddress: string,
  onInstallData: BytesLike,
  deploymentIndex: number = 0,
): Promise<Nexus> {
  const ownerAddress = await signer.getAddress();
  // Module initialization data, encoded
  const moduleInstallData = ethers.solidityPacked(["address"], [ownerAddress]);

  const accountAddress = await accountFactory.computeAccountAddress(
    ownerAddress,
    deploymentIndex,
  );

  await entryPoint.depositTo(accountAddress, { value: to18(1) });

  await mockToken.mint(accountAddress, to18(100));

  await accountFactory.createAccount(ownerAddress, deploymentIndex);

  const Nexus = await ethers.getContractFactory("Nexus");

  // Attach the Nexus contract to the deployed address
  const deployedNexus = Nexus.attach(accountAddress) as Nexus;

  return deployedNexus;
}
