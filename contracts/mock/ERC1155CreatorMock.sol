// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ERC1155Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC1155Creator.sol";

contract ERC1155CreatorMock is ERC1155Creator {
    uint256 internal _id;

    function mintMock(
        address account,
        uint256 amount,
        bytes memory data
    ) public {
        ERC1155Creator._mint(account, ++_id, amount, data);
    }
}
