import { ethers } from "hardhat";
import { buildPackedUserOp, generateUseropCallData } from "./operationHelpers";
import { ExecutionMethod, ModuleParams, ModuleType } from "./types";

// define mode and exec type enums
export const CALLTYPE_SINGLE = "0x00"; // 1 byte
export const CALLTYPE_BATCH = "0x01"; // 1 byte
export const EXECTYPE_DEFAULT = "0x00"; // 1 byte
export const EXECTYPE_TRY = "0x01"; // 1 byte
export const CALLTYPE_DELEGATE = "0xFF"; // 1 byte
export const MODE_DEFAULT = "0x00000000"; // 4 bytes
export const UNUSED = "0x00000000"; // 4 bytes
export const MODE_PAYLOAD = "0x00000000000000000000000000000000000000000000"; // 22 bytes
export const ERC1271_MAGICVALUE = "0x1626ba7e";
export const ERC1271_INVALID = "0xffffffff";

export const GENERIC_FALLBACK_SELECTOR = "0xcb5baf0f";

export const installModule = async (args: ModuleParams) => {
  const {
    deployedNexus,
    entryPoint,
    module,
    validatorModule,
    accountOwner,
    bundler,
    moduleType,
    data,
  } = args;
  const installModuleData = await generateUseropCallData({
    executionMethod: ExecutionMethod.Execute,
    targetContract: deployedNexus,
    functionName: "installModule",
    args: [
      moduleType,
      await module.getAddress(),
      data ? data : ethers.hexlify(await accountOwner.getAddress()),
    ],
  });

  const userOp = buildPackedUserOp({
    sender: await deployedNexus.getAddress(),
    callData: installModuleData,
  });

  const nonce = await entryPoint.getNonce(
    userOp.sender,
    ethers.zeroPadBytes((await validatorModule.getAddress()).toString(), 24),
  );
  userOp.nonce = nonce;

  const userOpHash = await entryPoint.getUserOpHash(userOp);
  const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
  userOp.signature = signature;

  return await entryPoint.handleOps([userOp], await bundler.getAddress());
};

export const uninstallModule = async (args: ModuleParams) => {
  const {
    deployedNexus,
    entryPoint,
    module,
    validatorModule,
    accountOwner,
    bundler,
    moduleType,
    data,
  } = args;
  const uninstallModuleData = await generateUseropCallData({
    executionMethod: ExecutionMethod.Execute,
    targetContract: deployedNexus,
    functionName: "uninstallModule",
    args: [
      moduleType,
      await module.getAddress(),
      data ? data : ethers.hexlify(await accountOwner.getAddress()),
    ],
  });

  const userOp = buildPackedUserOp({
    sender: await deployedNexus.getAddress(),
    callData: uninstallModuleData,
  });

  const nonce = await entryPoint.getNonce(
    userOp.sender,
    ethers.zeroPadBytes((await validatorModule.getAddress()).toString(), 24),
  );
  userOp.nonce = nonce;

  const userOpHash = await entryPoint.getUserOpHash(userOp);
  const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
  userOp.signature = signature;

  await entryPoint.handleOps([userOp], await bundler.getAddress());
};
