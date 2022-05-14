// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {DirectSale} from "./DirectSale.sol";

contract Marketplace is DirectSale {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _saleId;
}
