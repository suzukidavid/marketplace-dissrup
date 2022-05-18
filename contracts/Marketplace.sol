// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import {DirectSale} from "./DirectSale.sol";

import {Core} from "./Core.sol";

error Only_Admin_Can_Access();

enum TokenStandard {
    ERC721,
    ERC1155
}

contract Marketplace is Initializable, DirectSale, AccessControlUpgradeable {
    event RegisterContract(
        address contractAddress,
        TokenStandard tokenStandard
    );

    event SetAdmin(address account);

    event SetDissrupPayment(address dissrupPayout);

    event RevokeAdmin(address account);

    // @custom:oz-upgrades-unsafe-allow constructor
    //constructor() initializer {}

    function initialize(address dissrupPayout) public initializer {
        __AccessControl_init_unchained();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        super._setDissrupPayment(dissrupPayout);
    }

    function addContractAllowlist(
        address contractAddress,
        TokenStandard tokenStandard
    ) external onlyAdmin {
        super._addContractAllowlist(contractAddress);

        emit RegisterContract(contractAddress, tokenStandard);
    }

    function setDissrupPayment(address dissrupPayout) external onlyAdmin {
        super._setDissrupPayment(dissrupPayout);

        emit SetDissrupPayment(dissrupPayout);
    }

    function setAdmin(address account) external onlyAdmin {
        _setupRole(DEFAULT_ADMIN_ROLE, account);

        emit SetAdmin(account);
    }

    function revokeAdmin(address account) external onlyAdmin {
        require(msg.sender != account, "Cannot remove yourself!");

        _revokeRole(DEFAULT_ADMIN_ROLE, account);

        emit RevokeAdmin(account);
    }

    modifier onlyAdmin() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert Only_Admin_Can_Access();
        }
        _;
    }
}
