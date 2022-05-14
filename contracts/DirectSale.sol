// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Constants} from "./Constants.sol";
import {Core} from "./Core.sol";

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "hardhat/console.sol";

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

abstract contract DirectSale is Initializable, Core, Constants {
    struct DirectSaleList {
        address seller;
        uint256 amount;
        uint256 price;
    }
    uint256 internal _directSaleId;
    mapping(address => mapping(uint256 => mapping(uint256 => DirectSaleList)))
        private assetAndSaleIdToDirectSale;

    // function initialize(address _dissrupPayoutAddress) public initializer {
    // }
    event ListDirectSale(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId,
        address seller,
        uint256 amount,
        uint256 price
    );

    function listDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        uint256 saleId
    ) external {
        //} nonReentrant {
        if (price < Constants.MIN_PRICE) {
            // revert in case of price below MIN_PRICE
            revert Direct_Sale_Price_Too_Low();
        }
        if (amount == 0) {
            revert Direct_Sale_Amount_Cannot_Be_Zero();
        }
        address seller;

        if (saleId == 0) {
            // new list
            saleId = ++_directSaleId;
            console.log("saleId", saleId);
        }
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller == address(0)) {
            //new list
            console.log("new list, saleId", saleId);
            seller = msg.sender;
            _trasferNFT(seller, address(this), nftAddress, tokenId, amount);
            directSale.seller = seller;
            directSale.amount = amount;
            directSale.price = price;
            _printSale(
                "In new List",
                nftAddress,
                tokenId,
                directSale.amount,
                directSale.seller,
                directSale.price,
                saleId
            );
        } else {
            //not new list, update current list
            console.log("NOT a new list, saleId", saleId);
            seller = directSale.seller;
            if (price == directSale.price && amount == directSale.amount) {
                revert Direct_Sale_NFT_Already_Listed();
            }
            if (seller != msg.sender) {
                revert Direct_Sale_Not_The_Owner(msg.sender, seller);
            }
            // add amount to list
            if (amount > directSale.amount) {
                console.log("add amount");
                uint256 addedAmount = amount - directSale.amount;
                _trasferNFT(
                    seller,
                    address(this),
                    nftAddress,
                    tokenId,
                    addedAmount
                );
                directSale.amount = amount;
            }
            // reduce amount of asset
            else if (amount < directSale.amount) {
                console.log("reduce amount");
                uint256 reducedAmount = directSale.amount - amount;
                _trasferNFT(
                    address(this),
                    seller,
                    nftAddress,
                    tokenId,
                    reducedAmount
                );
                directSale.amount = amount;
            }
            // change price
            if (price != directSale.price) {
                directSale.price = price;
            }
            _printSale(
                "in update sale",
                nftAddress,
                tokenId,
                directSale.amount,
                directSale.seller,
                directSale.price,
                saleId
            );
        }
        emit ListDirectSale(saleId, nftAddress, tokenId, seller, amount, price);
    }

    function _unlist(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId
    ) internal {
        delete assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];
    }

    /* remove me before deploy*/
    /* print helpers*/
    function _printSale(
        string memory name,
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        address seller,
        uint256 price,
        uint256 saleId
    ) internal view {
        console.log("-#-#-#-#-#-#-#-#-#- %s -#-#-#-#-#-#-#-#-#-#-#-#-#", name);
        console.log("directSale: ");
        console.log("nftAddress: ", nftAddress);
        console.log("tokenId: ", tokenId);
        console.log("saleId: ", saleId);
        console.log("seller: ", seller);
        console.log("amount: ", amount);
        console.log("price: ", price);
        console.log(
            "-#-#-#-#-#-#-#-#-#-# ^ # ^ # ^ # ^#-#-#-#-#-#-#-#-#-#-#-#-#-#"
        );
    }
}
