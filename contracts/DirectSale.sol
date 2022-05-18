// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Constants} from "./Constants.sol";

import {Core} from "./Core.sol";

import {Payment} from "./Payment.sol";

/*
 * @notice revert in case of price below MIN_PRICE
 */
error Direct_Sale_Price_Too_Low();
/*
 * @notice revert in case of nft is no chages
 */
error Direct_Sale_params_Did_Not_Changed();
/*
 * @notice revert in case of nft is been on list
 */
error Direct_Sale_Not_The_Owner(address msgSender, address seller);

error Direct_Sale_Amount_Cannot_Be_Zero();

error Direct_Sale_Contract_Address_Is_Not_Approved(address nftAddress);

error Direct_Sale_Not_A_Valid_Params_For_Buy();

error Direct_Sale_Required_Amount_To_Big_To_Buy();

error Direct_Sale_Not_Enough_Ether_To_Buy();

error Direct_Sale_Not_Valid_Params_For_Update();

abstract contract DirectSale is Initializable, Constants, Core, Payment {
    struct DirectSaleList {
        address seller;
        uint256 amount;
        uint256 price;
    }

    uint256 internal _directSaleId;

    mapping(address => mapping(uint256 => mapping(uint256 => DirectSaleList)))
        private assetAndSaleIdToDirectSale;

    event ListDirectSale(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId,
        address seller,
        uint256 amount,
        uint256 price
    );

    event UpdateDirectSale(
        uint256 saleId,
        address nftAddress,
        uint256 tokenId,
        address seller,
        uint256 amount,
        uint256 price
    );

    event CancelDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        address seller
    );

    event Buy(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        address buyer,
        address seller
    );

    function listDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 amount,
        uint256 price
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

        if (_saleContractAllowlist[nftAddress] == false) {
            // revert in case contract is not approved by dissrup
            revert Direct_Sale_Contract_Address_Is_Not_Approved(nftAddress);
        }

        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][++_directSaleId];

        address seller = msg.sender;

        // transfer asset to contract
        _trasferNFT(seller, address(this), nftAddress, tokenId, amount);

        // save to local map  the sale params
        directSale.seller = seller;
        directSale.amount = amount;
        directSale.price = price;

        emit ListDirectSale(
            _directSaleId,
            nftAddress,
            tokenId,
            seller,
            amount,
            price
        );
    }

    function updateDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount,
        uint256 price
    ) external {
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        address seller = directSale.seller;

        if (seller != msg.sender) {
            //revert in case the msg.sender is not the owner (the lister) of the list
            revert Direct_Sale_Not_The_Owner(msg.sender, seller);
        }

        if (price == directSale.price && amount == directSale.amount) {
            //revert in case no changes were made in list (price or amount)
            revert Direct_Sale_params_Did_Not_Changed();
        }

        if (amount == 0 || price < MIN_PRICE) {
            // revert not valid changes
            revert Direct_Sale_Not_Valid_Params_For_Update();
        }
        if (amount > directSale.amount) {
            // add amount to list
            _transferAdditionalNFTs(
                seller,
                address(this),
                nftAddress,
                tokenId,
                directSale.amount,
                amount
            );
        }
        // reduce amount of asset
        else if (amount < directSale.amount) {
            _transferAdditionalNFTs(
                address(this),
                seller,
                nftAddress,
                tokenId,
                directSale.amount,
                amount
            );

            // update storage
            directSale.amount = amount;
        }

        // change price
        if (price != directSale.price) {
            // update price in storage
            directSale.price = price;
        }

        emit UpdateDirectSale(
            saleId,
            nftAddress,
            tokenId,
            seller,
            amount,
            price
        );
    }

    function cancelDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) external {
        DirectSaleList memory directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (msg.sender != directSale.seller) {
            revert Direct_Sale_Not_The_Owner(msg.sender, directSale.seller);
        }

        _trasferNFT(
            address(this),
            directSale.seller,
            nftAddress,
            tokenId,
            directSale.amount
        );

        _unlist(nftAddress, tokenId, saleId);

        emit CancelDirectSale(nftAddress, tokenId, saleId, directSale.seller);
    }

    function buyDirectSale(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId,
        uint256 amount
    ) external payable {
        DirectSaleList storage directSale = assetAndSaleIdToDirectSale[
            nftAddress
        ][tokenId][saleId];

        if (directSale.seller == address(0)) {
            // revert in case of a direct sale list is not exist
            revert Direct_Sale_Not_A_Valid_Params_For_Buy();
        }

        if (directSale.amount < amount) {
            // revert in case the require to buy is more then exist in marketplace
            revert Direct_Sale_Required_Amount_To_Big_To_Buy();
        }

        uint256 totalPrice = directSale.price * amount;
        address buyer = msg.sender;
        uint256 payment = msg.value;

        if (payment < totalPrice) {
            revert Direct_Sale_Not_Enough_Ether_To_Buy();
        }

        if (payment > totalPrice) {
            uint256 refund = payment - totalPrice;
            payable(buyer).transfer(refund);
        }

        _trasferNFT(address(this), buyer, nftAddress, tokenId, amount);

        directSale.amount = directSale.amount - amount;

        _splitPayment(directSale.seller, totalPrice, nftAddress, tokenId);

        emit Buy(nftAddress, tokenId, saleId, amount, buyer, directSale.seller);

        if (directSale.amount == 0) {
            _unlist(nftAddress, tokenId, saleId);
        }
    }

    function _unlist(
        address nftAddress,
        uint256 tokenId,
        uint256 saleId
    ) internal {
        delete assetAndSaleIdToDirectSale[nftAddress][tokenId][saleId];
    }
}
