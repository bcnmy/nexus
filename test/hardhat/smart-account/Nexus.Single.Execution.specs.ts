import { ExecutionMethod } from "../utils/types";
import { expect } from "chai";

import { Signer, parseEther } from "ethers";
import {
  K1ValidatorFactory,
  Counter,
  EntryPoint,
  MockExecutor,
  MockToken,
  MockValidator,
  Nexus,
  MockSigVerifier,
} from "../../../typechain-types";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ModuleType } from "../utils/types";
import { deployContract, deployContractsAndSAFixture } from "../utils/deployment";
import {
  generateUseropCallData,
  buildPackedUserOp,
  MODE_VALIDATION,
  getNonce,
  numberTo3Bytes,
} from "../utils/operationHelpers";
import { ethers } from "hardhat";
import {
  CALLTYPE_SINGLE,
  EXECTYPE_DEFAULT,
  EXECTYPE_TRY,
  MODE_DEFAULT,
  MODE_PAYLOAD,
  UNUSED,
  uninstallModule,
} from "../utils/erc7579Utils";
import { encodeData } from "../utils/encoding";

describe("Nexus Single Execution", () => {
  let factory: K1ValidatorFactory;
  let entryPoint: EntryPoint;
  let bundler: Signer;
  let validatorModule: MockValidator;
  let executorModule: MockExecutor;
  let counter: Counter;
  let alice: Signer;
  let smartAccount: Nexus;
  let smartAccountOwner: Signer;
  let deployer: Signer;

  let factoryAddress: string;
  let entryPointAddress: string;
  let bundlerAddress: string;
  let validatorModuleAddress: string;
  let executorModuleAddress: string;
  let counterAddress: string;
  let smartAccountAddress: string;
  let aliceAddress: string;
  let smartAccountOwnerAddress: string;
  let mockToken: MockToken;
  let mockSigVerifier: MockSigVerifier;

  beforeEach(async () => {
    const setup = await loadFixture(deployContractsAndSAFixture);
    entryPoint = setup.entryPoint;
    factory = setup.nexusK1Factory;
    bundler = ethers.Wallet.createRandom();
    validatorModule = setup.mockValidator;
    executorModule = setup.mockExecutor;
    smartAccountOwner = setup.accountOwner;
    alice = setup.aliceAccountOwner;
    smartAccount = setup.deployedNexus;
    counter = setup.counter;
    deployer = setup.deployer;
    mockToken = setup.mockToken;
    mockSigVerifier = await deployContract<MockSigVerifier>(
      "MockSigVerifier",
      deployer,
    );

    factoryAddress = await factory.getAddress();
    entryPointAddress = await entryPoint.getAddress();
    bundlerAddress = await bundler.getAddress();
    validatorModuleAddress = await validatorModule.getAddress();
    executorModuleAddress = await executorModule.getAddress();
    counterAddress = await counter.getAddress();
    smartAccountAddress = await smartAccount.getAddress();
    smartAccountOwnerAddress = await smartAccountOwner.getAddress();
    aliceAddress = await alice.getAddress();


    // First install the executor module on the smart account
    const isOwner = await validatorModule.isOwner(
      smartAccountAddress,
      smartAccountOwnerAddress,
    );

    expect(isOwner).to.be.true;

    const installModuleData = await generateUseropCallData({
      executionMethod: ExecutionMethod.Execute,
      targetContract: smartAccount,
      functionName: "installModule",
      args: [ModuleType.Execution, executorModuleAddress, ethers.hexlify("0x")],
    });

    const userOp = buildPackedUserOp({
      sender: smartAccountAddress,
      callData: installModuleData,
    });

    const nonce = await getNonce(
      entryPoint,
      userOp.sender,
      MODE_VALIDATION,
      validatorModuleAddress.toString(),
      numberTo3Bytes(10),
    );
    userOp.nonce = nonce;

    const userOpHash = await entryPoint.getUserOpHash(userOp);
    const signature = await smartAccountOwner.signMessage(
      ethers.getBytes(userOpHash),
    );
    userOp.signature = signature;

    await entryPoint.handleOps([userOp], bundlerAddress);

    const isInstalled = await smartAccount.isModuleInstalled(
      ModuleType.Execution,
      executorModuleAddress,
      ethers.hexlify("0x"),
    );

    expect(isInstalled).to.be.true;
  });

  describe("Nexus Transaction Execution", () => {
    it("Should execute a token transfer through handleOps", async () => {
      const recipient = smartAccountOwnerAddress;
      const amount = parseEther("1");

      // Log the chainId
      const chainId = await ethers.provider.getNetwork().then(network => network.chainId);
      console.log("Current chainId:", chainId);

      const callData = await generateUseropCallData({
        executionMethod: ExecutionMethod.Execute,
        targetContract: mockToken,
        functionName: "transfer",
        args: [recipient, amount],
      });

      const userOp = buildPackedUserOp({
        sender: smartAccountAddress,
        callData,
      });
      userOp.callData = callData;

      const nonce = await getNonce(
        entryPoint,
        userOp.sender,
        MODE_VALIDATION,
        validatorModuleAddress.toString(),
        numberTo3Bytes(157),
      );
      userOp.nonce = nonce;

      console.log("userOp", userOp);

      const userOpHash = await entryPoint.getUserOpHash(userOp);
      console.log("userOpHash", userOpHash);

      // Signature received from DAN by putting the exact userOp
      userOp.signature = "0x65ea543c9da64e2674d74f2ad56e83d6cf022040e82cc181ddb2ef575e5fc74a05896509d2309d5ee0daf9fcfb8528937c590900caff891c1e2a43a8fb749cc3";
      const signer = "0xFbdA35D7E3b7525E25B939BEd98a9e7b921000b1" // EOA from pubkey generated by DAN

      const isValid = await mockSigVerifier.verify.staticCall(userOpHash, userOp.signature, signer);
      console.log("isValid", isValid);

      // // Fund the EntryPoint with some ETH to cover gas costs
      // await deployer.sendTransaction({
      //   to: entryPointAddress,
      //   value: parseEther("1"),
      // });

      // // Impersonate the EntryPoint contract
      // await ethers.provider.send("hardhat_impersonateAccount", [entryPointAddress]);
      // const entryPointSigner = await ethers.provider.getSigner(entryPointAddress);

      // // Call validateUserOp as the EntryPoint
      // // Make a static call to validateUserOp and read the result
      // const isValidResult = await smartAccount.connect(entryPointSigner).validateUserOp.staticCall(
      //   userOp,
      //   userOpHash,
      //   0
      // );

      // console.log("isValidResult", isValidResult);
      // // Check if the operation is valid (validationData == 0)
      // const isValid = isValidResult === 0n;
      // console.log("isValid", isValid);

      // // Stop impersonating the EntryPoint
      // await ethers.provider.send("hardhat_stopImpersonatingAccount", [entryPointAddress]);
    });
  });
});