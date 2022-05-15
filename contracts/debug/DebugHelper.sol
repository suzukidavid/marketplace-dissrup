// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;
import "hardhat/console.sol";

contract DebugHelper {
    function printSale(
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
