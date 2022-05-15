// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {DirectSale} from "./DirectSale.sol";
import {Core} from "./Core.sol";
import {AdminControl} from "@manifoldxyz/libraries-solidity/contracts/access/AdminControl.sol";

contract Marketplace is DirectSale, AdminControl {
    mapping(address => bool) private saleContractAllowlist;

    function addContractAllowlist(address contractAddress)
        external
        adminRequired
    {
        saleContractAllowlist[contractAddress] = true;
        super._addContractAllowlist(contractAddress);
    }

    /**
     * See {IERC165-supportsInterface}.
     */
}
