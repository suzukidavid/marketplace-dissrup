// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {ERC721Creator} from "@manifoldxyz/creator-core-solidity/contracts/ERC721Creator.sol";

contract ERC721CreatorMock is ERC721Creator {
    constructor() ERC721Creator("721Mock", "721MOCK") {}

    function mintBaseMock(address to, string memory uri)
        public
        returns (uint256)
    {
        return ERC721Creator._mintBase(to, uri);
    }
}
