// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IMarketplace {
    function getCurrentSaleId() external view returns (uint256);

    function incrementSaleId() external;
}
