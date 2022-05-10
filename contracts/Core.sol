// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

error Core_Amount_Is_Not_Valid_For_ERC721();

abstract contract Core {
    using ERC165Checker for address;

    function _transferToMarketplace(
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (_isERC721(nftAddress)) {
            if (amount > 1) {
                revert Core_Amount_Is_Not_Valid_For_ERC721();
            }
            IERC721(nftAddress).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
        } else if (_isERC1155(nftAddress)) {
            IERC1155(nftAddress).safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                ""
            );
        }
    }

    function _transferFromMarketplace(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address to
    ) internal {
        if (_isERC721(nftAddress)) {
            IERC721(nftAddress).transferFrom(address(this), to, tokenId);
        } else {
            IERC1155(nftAddress).safeTransferFrom(
                address(this),
                to,
                tokenId,
                amount,
                ""
            );
        }
    }

    function _isERC1155(address nftAddress) private view returns (bool) {
        return nftAddress.supportsInterface(type(IERC721).interfaceId);
    }

    function _isERC721(address nftAddress) private view returns (bool) {
        return nftAddress.supportsInterface(type(IERC1155).interfaceId);
    }
}
