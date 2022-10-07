//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.3;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PubkeyRouterAndPermissions} from "./PubkeyRouterAndPermissions.sol";
import {PKPNFT} from "./PKPNFT.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// TODO: tests for the mintGrantAndBurn function, withdraw function, some of the setters, transfer function, freeMint and freeMintGrantAndBurn

/// @title Programmable Keypair NFT
///
/// @dev This is the contract for the PKP NFTs
///
/// Simply put, whomever owns a PKP NFT can ask that PKP to sign a message.
/// The owner can also grant signing permissions to other eth addresses
/// or lit actions
contract PKPHelper is Ownable, IERC721Receiver {
    /* ========== STATE VARIABLES ========== */

    PKPNFT public pkpNFT;
    PubkeyRouterAndPermissions public router;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _pkpNft, address _router) {
        pkpNFT = PKPNFT(_pkpNft);
        router = PubkeyRouterAndPermissions(_router);
    }

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mintNextAndAddAuthMethods(
        uint keyType,
        bytes32 permittedIpfsIdDigest,
        uint8 permittedIpfsHashFunction,
        uint8 permittedIpfsSize,
        address permittedAddress,
        uint permittedAuthMethodType,
        bytes memory permittedAuthMethodId
    ) public payable returns (uint) {
        // mint the nft and forward the funds
        uint tokenId = pkpNFT.mintNext{value: msg.value}(keyType);

        // permit the action
        if (permittedIpfsIdDigest != 0) {
            router.registerAndAddPermittedAction(
                tokenId,
                permittedIpfsIdDigest,
                permittedIpfsHashFunction,
                permittedIpfsSize
            );
        }

        // permit the address
        if (permittedAddress != address(0)) {
            router.addPermittedAddress(tokenId, permittedAddress);
        }

        // permit the auth method
        if (permittedAuthMethodType != 0) {
            router.addPermittedAuthMethod(
                tokenId,
                permittedAuthMethodType,
                permittedAuthMethodId
            );
        }
        pkpNFT.safeTransferFrom(address(this), msg.sender, tokenId);
        return tokenId;
    }

    function setPkpNftAddress(address newPkpNftAddress) public onlyOwner {
        pkpNFT = PKPNFT(newPkpNftAddress);
    }

    function setRouterAddress(address newRouterAddress) public onlyOwner {
        router = PubkeyRouterAndPermissions(newRouterAddress);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        // only accept transfers from the pkpNft contract
        require(
            msg.sender == address(pkpNFT),
            "PKPHelper: only accepts transfers from the PKPNFT contract"
        );
        return this.onERC721Received.selector;
    }
}
