// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Constants} from "./Constants.sol";
import {Core} from "./Core.sol";

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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

error Contract_Address_Is_Not_Approved(address nftAddress);

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
            // revert in case amount is 0
            revert Direct_Sale_Amount_Cannot_Be_Zero();
        }
        if (saleContractAllowlist[nftAddress] == false) {
            // revert in case contract is not approved by dissrup
            revert Contract_Address_Is_Not_Approved(nftAddress);
        }

        address seller;
        if (saleId == 0) {
            // new list
            saleId = ++_directSaleId;
        }

        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller == address(0)) {
            //if no seller, it is a new list
            seller = msg.sender;

            // transfer asset to contract
            _trasferNFT(seller, address(this), nftAddress, tokenId, amount);

            // save to local map  the sale params
            directSale.seller = seller;
            directSale.amount = amount;
            directSale.price = price;
        } else {
            //not new list, update current list

            seller = directSale.seller;

            if (price == directSale.price && amount == directSale.amount) {
                //revert in case no changes were made in list (price or amount)
                revert Direct_Sale_NFT_Already_Listed();
            }
            if (seller != msg.sender) {
                //revert in case the msg.sender is not the owner (the lister) of the list
                revert Direct_Sale_Not_The_Owner(msg.sender, seller);
            }

            // add amount to list
            if (amount > directSale.amount) {
                // calculate the delta between the listed amount and the required amount
                uint256 addedAmount = amount - directSale.amount;

                // transfer to marketplace the delta
                _trasferNFT(
                    seller,
                    address(this),
                    nftAddress,
                    tokenId,
                    addedAmount
                );

                // update new amount in storage
                directSale.amount = amount;
            }
            // reduce amount of asset
            else if (amount < directSale.amount) {
                // calculate the delta between the listed amount and the required amount
                uint256 reducedAmount = directSale.amount - amount;

                // transfer to seller back the delta amount of tokens
                _trasferNFT(
                    address(this),
                    seller,
                    nftAddress,
                    tokenId,
                    reducedAmount
                );

                // update storage
                directSale.amount = amount;
            }

            // change price
            if (price != directSale.price) {
                // update price in storage
                directSale.price = price;
            }
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
}
