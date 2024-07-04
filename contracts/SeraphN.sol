// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract SeraphN is
ContextUpgradeable,
AccessControlEnumerableUpgradeable,
ERC721EnumerableUpgradeable,
ERC721BurnableUpgradeable,
ERC721PausableUpgradeable,
ERC2981Upgradeable,
ReentrancyGuardUpgradeable
{
    event SetBaseURI(
        address indexed sender,
        string baseTokenURI
    );

    event Mint(
        address sender,
        address to,
        uint256 tokenId,
        string content
    );

    event CrossChain(
        address sender,
        uint256 tokenId,
        string content,
        string destChain
    );

    event MintFromCrossChain(
        address sender,
        address to,
        uint256 tokenId,
        string content,
        string srcChain
    );

    bytes32 public constant GAME_MINTER_ROLE = keccak256("GAME_MINTER_ROLE");
    bytes32 public constant ADMIN_MINTER_ROLE = keccak256("ADMIN_MINTER_ROLE");
    bytes32 public constant CROSS_MINTER_ROLE = keccak256("CROSS_MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    string private _baseTokenURI;
    mapping(uint256 => string) private contents;

    modifier onlyAdmin(bytes32 role) {
        require(hasRole(role, _msgSender()), "Permission denied");
        _;
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        address owner
    ) public initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC721_init_unchained(name, symbol);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();
        __ERC721Pausable_init_unchained();
        __ERC2981_init_unchained();
        __ReentrancyGuard_init_unchained();
        _baseTokenURI = baseTokenURI;
        _setupRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }
    function setBaseURI(string calldata baseTokenURI) external onlyAdmin(DEFAULT_ADMIN_ROLE) {
        _baseTokenURI = baseTokenURI;
        emit SetBaseURI(_msgSender(), baseTokenURI);
    }

    function getContent(uint tokenId) external view returns(string memory){
        _requireMinted(tokenId);
        return contents[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, contents[tokenId]), ".json")) : contents[tokenId];
    }

    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external virtual {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            transferFrom(from, to, tokenIds[i]);
        }
    }

    function mint(
        address to,
        uint256 tokenId,
        string calldata content
    ) public onlyAdmin(GAME_MINTER_ROLE) nonReentrant {
        require(
            bytes(content).length > 0,
            "content is empty"
        );
        _mint(to, tokenId);
        contents[tokenId] = content;
        emit Mint(_msgSender(), to, tokenId, content);
    }

    function batchMint(
        address[] calldata to,
        uint256[] calldata tokenId,
        string[] calldata content
    ) public onlyAdmin(GAME_MINTER_ROLE) nonReentrant {
        require(
            to.length == content.length &&
            to.length  > 0,
            'batchMint: length err'
        );
        require(
            to.length == tokenId.length &&
            to.length  > 0,
            'batchMint: length2 err'
        );
        uint count = to.length;
        for(uint i = 0; i < count; ++i) {
            require(
                bytes(content[i]).length > 0,
                "content is empty"
            );
            _mint(to[i], tokenId[i]);
            contents[tokenId[i]] = content[i];
            emit Mint(_msgSender(), to[i], tokenId[i], content[i]);
        }
    }

    function crossChain(
        uint256 tokenId,
        string calldata destChain
    ) external onlyAdmin(CROSS_MINTER_ROLE) nonReentrant {
        burn(tokenId);
        emit CrossChain(_msgSender(), tokenId, contents[tokenId], destChain);
    }

    function mintFromCrossChain(
        address to,
        uint256 tokenId,
        string calldata content,
        string calldata srcChain
    ) external onlyAdmin(CROSS_MINTER_ROLE) nonReentrant  {
        require(
            bytes(content).length > 0,
            "content is empty"
        );
        _mint(to, tokenId);
        contents[tokenId] = content;
        emit MintFromCrossChain(_msgSender(), to, tokenId, content, srcChain);
    }

    function batchBurn(uint256[] calldata tokenIds) public onlyAdmin(DEFAULT_ADMIN_ROLE) {
        require(tokenIds.length > 0, "tokenIds must not be empty");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _burn(tokenIds[i]);
        }
    }

    function setRoyaltyInfo(
        address _recipient,
        uint96 _feeNumerator
    ) external onlyAdmin(DEFAULT_ADMIN_ROLE) {
        _setDefaultRoyalty(_recipient, _feeNumerator);
    }

    function pause() external onlyAdmin(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyAdmin(PAUSER_ROLE) {
        _unpause();
    }

    receive() external payable {
    }

    function withdrawERC20(IERC20 token, uint256 amount, address payable receiver) external onlyAdmin(DEFAULT_ADMIN_ROLE) {
        token.transfer(receiver, amount);
    }

    function withdraw(address payable receiver) external onlyAdmin(DEFAULT_ADMIN_ROLE) {
        payable(receiver).transfer(address(this).balance);
    }

    function withdrawNFT(IERC721 nft, uint256 tokenId, address to) external onlyAdmin(DEFAULT_ADMIN_ROLE) {
        nft.transferFrom(address(this), to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}