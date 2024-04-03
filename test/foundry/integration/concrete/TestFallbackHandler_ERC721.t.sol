// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";

contract TestFallbackHandler_ERC721 is SmartAccountTestLab {
    NFT public nft;
    uint256 public tokenId = 1;

    event NFTReceived(address operator, address from, uint256 tokenId, bytes data);

    function setUp() public {
        init();
        nft = new NFT("TestNFT", "TNFT");


        // Mint an NFT to the test contract
        nft.mint(address(this), tokenId);
        
        bytes memory customData = abi.encode(bytes4(0xaabbccdd));

        // Install MockHandler as the fallback handler for ALICE_ACCOUNT
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            MODULE_TYPE_FALLBACK, 
            address(HANDLER_MODULE), 
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(ALICE_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(ALICE, ALICE_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(address(ALICE.addr)));

        assertEq(ALICE_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), true, "Fallback handler not installed");
    }
    // Test that NFT is correctly transferred to the SmartAccount and handled by the fallback handler
    function test_FallbackHandlerReceivesERC721Transfer() public {
        address ownerOfTokenBefore = nft.ownerOf(tokenId);
        assertNotEq(ownerOfTokenBefore, address(ALICE_ACCOUNT), "Fallback handler did not correctly receive the NFT");

        vm.expectEmit(true, true, true, true);
        emit FallbackHandlerTriggered();

        // Transfer NFT to the SmartAccount (which should invoke the fallback handler)
        nft.safeTransferFrom(address(this), address(ALICE_ACCOUNT), tokenId, "");

        // Verify ownership
        address ownerOfToken = nft.ownerOf(tokenId);
        assertEq(ownerOfToken, address(ALICE_ACCOUNT), "Fallback handler did not correctly receive the NFT");
    }
}
