// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {ERC1155} Asset, including:
 *
 *  - ability for holders to burn (destroy) their Assets
 *  - a minter role that allows for Asset minting (creation)
 *  - a pauser role that allows to stop all Asset transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */

contract AssetMock is
    Context,
    AccessControlEnumerable,
    ERC1155Burnable,
    ERC1155Pausable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SALE_CONTRACT_ROLE =
        keccak256("SALE_CONTRACT_ROLE");

    uint256 public id;
    uint256 public assetEnumCounter;
    uint256 public artworkId;
    uint256 public phygitalArtworkId;
    string public symbol;
    string public name;
    bool public publicMintingEnabled;

    event AddAssetType(uint256 indexed typeId, string assetType);
    event AssetTypeMinted(uint256 indexed assetId, uint256 assetType);

    mapping(uint256 => address) public creators;
    mapping(uint256 => uint256) public assetSupply;
    mapping(uint256 => string) public assetTypesEnum;
    mapping(uint256 => uint256) public assetTypes;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(
        string memory _uri,
        string memory _symbol,
        string memory _name
    ) ERC1155(_uri) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(MODERATOR_ROLE, _msgSender());

        assetEnumCounter = 0;

        artworkId = assetEnumCounter;
        addAssetType("ARTWORK");

        addAssetType("DIGITAL_COLLECTIBLE");

        addAssetType("PHYGITAL_COLLECTIBLE");

        phygitalArtworkId = assetEnumCounter;
        addAssetType("PHYGITAL_ARTWORK");

        addAssetType("EXTRA");

        symbol = _symbol;
        name = _name;

        id = 0;
    }

    /**
     * @dev Creates `amount` new Assets for `to`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(
        address to,
        uint256 amount,
        uint256 _assetType
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || publicMintingEnabled,
            "Asset: must have minter role to mint"
        );
        require(
            _assetType < assetEnumCounter,
            "Can't mint with an invalid type"
        );

        _isArtwork(_assetType, amount);

        creators[id] = to;
        assetSupply[id] = amount;
        assetTypes[id] = _assetType;

        uint256 currentId = id;

        id++;

        _mint(to, currentId, amount, "");

        emit AssetTypeMinted(currentId, _assetType);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(
        address to,
        uint256[] memory amounts,
        uint256[] memory types
    ) public virtual {
        require(
            hasRole(MINTER_ROLE, _msgSender()) || publicMintingEnabled,
            "Asset: must have minter role to mint"
        );

        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i = 0; i < amounts.length; i++) {
            _isArtwork(types[i], amounts[i]);

            creators[id] = to;
            assetSupply[id] = amounts[i];
            assetTypes[id] = types[i];
            ids[i] = id;

            emit AssetTypeMinted(id, types[i]);

            id++;
        }

        _mintBatch(to, ids, amounts, "");
    }

    /**
     * @dev Pauses all Asset transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Asset: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all Asset transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Asset: must have pauser role to unpause"
        );
        _unpause();
    }

    function addAssetType(string memory _enumType) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "must have admin role to add enum type"
        );

        assetTypesEnum[assetEnumCounter] = _enumType;
        emit AddAssetType(assetEnumCounter, _enumType);
        assetEnumCounter++;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC1155)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Pausable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function addSaleRole(address _account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to add sale contract"
        );
        grantRole(SALE_CONTRACT_ROLE, _account);
    }

    function revokeSaleRole(address _account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to remove sale contract"
        );
        revokeRole(SALE_CONTRACT_ROLE, _account);
    }

    function addMinterRole(address _account) public {
        require(
            hasRole(MODERATOR_ROLE, _msgSender()),
            "Asset: must have moderator role to add minter"
        );
        _setupRole(MINTER_ROLE, _account);
    }

    function revokeMinterRole(address _account) public {
        require(
            hasRole(MODERATOR_ROLE, _msgSender()),
            "Asset: must have moderator role to remove minter"
        );
        revokeRole(MINTER_ROLE, _account);
    }

    function addModeratorRole(address _account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to add moderator"
        );
        grantRole(MODERATOR_ROLE, _account);
    }

    function revokeModeratorRole(address _account) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to remove moderator"
        );
        revokeRole(MODERATOR_ROLE, _account);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        if (hasRole(SALE_CONTRACT_ROLE, _operator)) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    function setURI(string memory _uri) public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to change uri"
        );
        ERC1155._setURI(_uri);
    }

    function enablePublicMinting() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to enable public minting"
        );

        publicMintingEnabled = true;
    }

    function disablePublicMinting() public {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "Asset: must have admin role to enable public minting"
        );
        publicMintingEnabled = false;
    }

    function _isArtwork(uint256 _assetType, uint256 _amount) private view {
        if (_assetType == artworkId || _assetType == phygitalArtworkId) {
            require(_amount == 1, "Can't mint more than one Artwork");
        }
    }

    function creator(uint256 _assetId) public view returns (address) {
        return creators[_assetId];
    }
}
