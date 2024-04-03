import { ethers } from "hardhat";
import { buildPackedUserOp, generateUseropCallData } from "./operationHelpers";
import { ExecutionMethod, InstallModuleParams, ModuleType } from "./types";

// define mode and exec type enums
export const CALLTYPE_SINGLE = "0x00"; // 1 byte
export const CALLTYPE_BATCH = "0x01"; // 1 byte
export const EXECTYPE_DEFAULT = "0x00"; // 1 byte
export const EXECTYPE_TRY = "0x01"; // 1 byte
export const EXECTYPE_DELEGATE = "0xFF"; // 1 byte
export const MODE_DEFAULT = "0x00000000"; // 4 bytes
export const UNUSED = "0x00000000"; // 4 bytes
export const MODE_PAYLOAD = "0x00000000000000000000000000000000000000000000"; // 22 bytes

export const installModule = async (args: InstallModuleParams) => {
    // Re-install module
    const { deployedMSA, entryPoint, mockExecutor, mockValidator, accountOwner, bundler } = args;
    const installModuleData = await generateUseropCallData({
     executionMethod: ExecutionMethod.Execute,
     targetContract: deployedMSA,
     functionName: "installModule",
     args: [ModuleType.Execution, await mockExecutor.getAddress(), ethers.hexlify("0x")],
   });
 
   const userOp = buildPackedUserOp({
     sender: await deployedMSA.getAddress(),
     callData: installModuleData,
   });
 
   const nonce = await entryPoint.getNonce(
     userOp.sender,
     ethers.zeroPadBytes((await mockValidator.getAddress()).toString(), 24),
   );
   userOp.nonce = nonce; 
 
   const userOpHash = await entryPoint.getUserOpHash(userOp);
   const signature = await accountOwner.signMessage(ethers.getBytes(userOpHash));
   userOp.signature = signature;
 
   const balance = await ethers.provider.getBalance(await deployedMSA.getAddress());
 
   await entryPoint.handleOps([userOp], await bundler.getAddress());
 }