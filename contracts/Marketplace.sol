// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

contract Marketplace {
    using Counters for Counters.Counter;

    Counters.Counter private _saleId;

    function incrementSaleId() external {
        return _saleId.increment();
    }

    function getCurrentSaleId() external view returns (uint256) {
        return _saleId.current();
    }
}
