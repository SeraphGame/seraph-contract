// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

contract SeraphERC1155 is Initializable, ContextUpgradeable, ERC1155Upgradeable, AccessControlEnumerableUpgradeable, ERC1155PausableUpgradeable, ERC1155BurnableUpgradeable, ERC1155SupplyUpgradeable {
    using StringsUpgradeable for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private _name;
    string private _symbol;

    modifier onlyAdmin(bytes32 role) {
        require(hasRole(role, msg.sender), "Permission denied");
        _;
    }

    function initialize(string memory name_, string memory symbol_, string memory uri_, address owner_) public initializer {
        __ERC1155_init(uri_);
        __AccessControlEnumerable_init();
        __ERC1155Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();

        _name = name_;
        _symbol = symbol_;
        _setupRole(DEFAULT_ADMIN_ROLE, owner_);
        _setupRole(MINTER_ROLE, owner_);
        _setupRole(PAUSER_ROLE, owner_);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function setURI(string calldata newuri) public virtual onlyAdmin(DEFAULT_ADMIN_ROLE){
        _setURI(newuri);
    }

    function uri(uint256 id) public view override returns (string memory) {
        require(exists(id), "URI: nonexistent token");
        return bytes(super.uri(id)).length > 0 ? string.concat(super.uri(id), id.toString(), ".json") : "";
    }

    function submitURIEvent(uint256 tokenId) public virtual onlyAdmin(DEFAULT_ADMIN_ROLE){
        emit URI(uri(tokenId), tokenId);
    }

    function mint(address to, uint256 id, uint256 amount) public virtual onlyAdmin(MINTER_ROLE){
        _mint(to, id, amount, '');
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) public virtual onlyAdmin(MINTER_ROLE){
        _mintBatch(to, ids, amounts, '');
    }

    function pause() public virtual onlyAdmin(PAUSER_ROLE){
        _pause();
    }

    function unpause() public virtual onlyAdmin(PAUSER_ROLE){
        _unpause();
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Upgradeable, AccessControlEnumerableUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155Upgradeable, ERC1155PausableUpgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

    }

    uint256[50] private __gap;
}

