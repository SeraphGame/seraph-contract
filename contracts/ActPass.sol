// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ActPass is
    Context,
    ERC721Enumerable,
    ReentrancyGuard,
    Ownable
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdTracker;

    uint256 public constant MAX_SUPPLY = 999;

    mapping(address => uint256) private _whitelist;

    string private _baseTokenURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _tokenIdTracker.increment();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseTokenURI) public virtual onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(abi.encodePacked(baseURI, tokenId.toString()), ".json")) : "";
    }

    function addWhitelist(address account, uint256 mintAllowance) external virtual onlyOwner {
        _whitelist[account] = mintAllowance;
    }

    function removeWhitelist(address account) external virtual onlyOwner {
        _whitelist[account] = 0;
    }

    function getWhitelistMintAllowance(address account) external view returns (uint256) {
        return _whitelist[account];
    }

    function batchMint(address toAddress, uint256 mintAmount) external virtual nonReentrant {
        require(_whitelist[_msgSender()] >= mintAmount, "Not enough mint allowance");
        require(_tokenIdTracker.current() + mintAmount - 1 <= MAX_SUPPLY, "Exceeds maximum token supply");
        _whitelist[_msgSender()] -= mintAmount;
        for (uint256 i = 0; i < mintAmount; ++i) {
            _mint(toAddress, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    function mint(address toAddress) external virtual nonReentrant {
        require(_whitelist[_msgSender()] >= 1, "Not enough mint allowance");
        require(_tokenIdTracker.current() <= MAX_SUPPLY, "Exceeds maximum token supply");
        _whitelist[_msgSender()] -= 1;
        _mint(toAddress, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    function withdrawERC20(IERC20 token, uint256 amount) public onlyOwner {
        token.transfer(owner(), amount);
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override(ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
