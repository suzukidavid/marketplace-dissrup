// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Constants} from "./Constants.sol";
import {IMarketplace} from "./IMarketplace.sol";
import {Core} from "./Core.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/*
 * @notice revert in case of price below MIN_PRICE
 */
error Direct_Sale_Price_Too_Low();

/*
 * @notice revert in case of nft is been on list
 */
error Direct_Sale_NFT_Already_Listed();

error Direct_Sale_Not_The_Owner(address msgSender, address seller);

error Direct_Sale_Amount_Cannot_Be_Zero();

abstract contract DirectSale is Core, Constants, IMarketplace {
    IMarketplace private marketplace;

    constructor(address marketplaceContract) {
        marketplace = IMarketplace(marketplaceContract);
    }

    struct DirectSaleList {
        address seller;
        uint256 amount;
        uint256 price;
    }

    mapping(address => mapping(uint256 => mapping(uint256 => DirectSaleList)))
        private assetAndSaleIdToDirectSale;

    function listDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
    ) external {
        if (price < Constants.MIN_PRICE) {
            // revert in case of price below MIN_PRICE
            revert Direct_Sale_Price_Too_Low();
        }
        if (amount == 0) {
            revert Direct_Sale_Amount_Cannot_Be_Zero();
        }

        uint256 saleId = marketplace.getCurrentSaleId();

        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        address seller = directSale.seller;
        // if seller exist:
        if (seller != address(0)) {
            if (price == directSale.price && amount == directSale.amount) {
                revert Direct_Sale_NFT_Already_Listed();
            }
            if (seller != msg.sender) {
                revert Direct_Sale_Not_The_Owner(msg.sender, seller);
            }
            // add amount to list
            if (amount > directSale.amount) {
                uint256 addedAmount = amount - directSale.amount;
                _transferToMarketplace(
                    saleId,
                    nftAddress,
                    tokenId,
                    addedAmount
                );
            }
            // reduce amount of asset
            else if (amount < directSale.amount) {
                uint256 reducedAmount = directSale.amount - amount;
                _transferFromMarketplace(
                    saleId,
                    nftAddress,
                    tokenId,
                    reducedAmount,
                    seller
                );
            }

            if (price != directSale.price) {
                directSale.price = price;
            }
        }
    }

    function _transferToMarketplace(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId,
        uint256 amount
    ) internal virtual {
        address seller = assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId]
            .seller;
        if (seller == address(0)) {
            super._transferToMarketplace(nftAddress, tokenId, amount);
        } else if (msg.sender != seller) {
            revert Direct_Sale_Not_The_Owner(msg.sender, seller);
        }
        // else: asset alredy in marketplace, do noting and return;
    }

    function _transferFromMarketplace(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address to
    ) internal virtual {
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller != address(0)) {
            directSale.amount -= amount;
            if (directSale.amount == 0) {
                _unlist(saleId, nftAddress, tokenId);
            }
        }
        super._transferFromMarketplace(nftAddress, tokenId, amount, to);
    }

    function _unlist(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId
    ) internal {
        delete assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];
    }
}
