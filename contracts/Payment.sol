// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {ERC165CheckerUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import {Constants} from "./Constants.sol";

interface IRoyalties {
    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     */
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (address payable[] memory, uint256[] memory);
}

abstract contract Payment is Initializable, Constants {
    address internal _dissrupPayout;
    uint256 internal _dissrupBasisPoint;

    struct Royalties {
        address payable[] payees;
        uint256[] shares;
    }
    using ERC165CheckerUpgradeable for address;
    event PayToRoyalties(address payable[] payees, uint256[] shares);

    function initialize(address dissrupPayout) public virtual initializer {
        _dissrupPayout = dissrupPayout;
    }

    function _setDissrupPayment(address dissrupPayout) internal {
        _dissrupPayout = dissrupPayout;
    }

    function _splitPayment(
        address seller,
        uint256 price,
        address nftAddress,
        uint256 tokenId
    ) internal {
        // 15% of price
        uint256 dissrupCut = SafeMathUpgradeable.mul(
            SafeMathUpgradeable.div(price, 100),
            15
        );

        payable(_dissrupPayout).transfer(dissrupCut);

        uint256 _royaltiesCut = _payToRoyaltiesIfExist(
            nftAddress,
            tokenId,
            price
        );
        uint256 _sellerCut = (price) - (dissrupCut + _royaltiesCut);

        payable(seller).transfer(_sellerCut);
    }

    function _payToRoyaltiesIfExist(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) internal returns (uint256 royaltiesCuts) {
        (
            address payable[] memory payees,
            uint256[] memory shares
        ) = _getRoyaltiesIfExist(nftAddress, tokenId);

        for (uint256 i = 0; i < payees.length; i++) {
            uint256 cut = _getCut(price, shares[i]);

            royaltiesCuts += cut;

            payable(payees[i]).transfer(cut);
        }
        emit PayToRoyalties(payees, shares);
    }

    function _getCut(uint256 price, uint256 share)
        internal
        pure
        returns (uint256 cut)
    {
        // fix to 100% (from `1000` to `10`)
        uint256 shareFixedBasisPoint = SafeMathUpgradeable.div(
            share,
            ROYALTIES_BASIS_POINT
        );

        uint256 oneShare = SafeMathUpgradeable.div(price, 100);

        cut = SafeMathUpgradeable.mul(oneShare, shareFixedBasisPoint);
    }

    function _getRoyaltiesIfExist(address nftAddress, uint256 tokenId)
        internal
        view
        returns (address payable[] memory payees, uint256[] memory shares)
    {
        if (nftAddress.supportsInterface(type(IRoyalties).interfaceId)) {
            try IRoyalties(nftAddress).getRoyalties(tokenId) returns (
                address payable[] memory _payees,
                uint256[] memory _shares
            ) {
                if (_payees.length == _shares.length) {
                    return (_payees, _shares);
                }
            } catch // solhint-disable-next-line no-empty-blocks
            {
                // Fall through
            }
        }
    }
}
