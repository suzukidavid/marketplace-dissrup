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

    function setRoyalty(
        uint256 tokenId,
        address payable[] calldata payees,
        uint256[] calldata shares
    ) public {
        _setRoyalties(tokenId, payees, shares);
    }

    function getRoyalty(uint256 tokenId)
        public
        view
        returns (address payable[] memory _payees, uint256[] memory _shares)
    {
        (_payees, _shares) = _getRoyalties(tokenId);
    }

    function getTokenBalance(address account, uint256 token)
        public
        view
        returns (uint256)
    {
        address owner = ownerOf(token);
        if (account == owner) {
            return 1;
        }
        return 0;
    }
}
