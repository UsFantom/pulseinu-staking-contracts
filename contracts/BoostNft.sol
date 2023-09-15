// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBoostNft } from "./interface/IBoostNft.sol";
import { IStakingPool } from "./interface/IStakingPool.sol";

/// @title BoostNft
/// @author Bounyavong
/// @dev BoostNft is a ERC721 standard NFT
contract BoostNft is IBoostNft, ERC721Enumerable, AccessControlEnumerable {
    using Strings for uint256;
    using SafeERC20 for IERC20;

    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant MAX_ART_COUNT = 1500;

    address public pulseInuTokenAddress;
    address public stakingPoolAddress;

    mapping(TokenType => uint256) public tokenTypePrice;
    mapping(TokenType => uint256) public tokenTypeSupply;
    mapping(uint256 => TokenType) public override tokenIdToType;

    // Base URI for each token
    string public baseURI;

    /** EVENT */
    // Event token minted by the burner
    event TokenMinted(address indexed burner, uint256 indexed tokenId, TokenType tokenType);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _myBaseUri,
        uint256 _legendaryPrice,
        uint256 _collectorPrice,
        address _pulseInuTokenAddress
    ) ERC721(_name, _symbol) {
        baseURI = _myBaseUri;
        tokenTypePrice[TokenType.Legendary] = _legendaryPrice;
        tokenTypePrice[TokenType.Collector] = _collectorPrice;
        pulseInuTokenAddress = _pulseInuTokenAddress;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(AccessControlEnumerable, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /** USER */

    /**
     * @dev mint a token
     */
    function mint(TokenType _tokenType) external {
        IERC20(pulseInuTokenAddress).safeTransferFrom(msg.sender, BURN_ADDRESS, tokenTypePrice[_tokenType]);
        uint256 tokenId = totalSupply();
        _mint(msg.sender, tokenId);
        tokenIdToType[tokenId] = _tokenType;
        tokenTypeSupply[_tokenType]++;

        emit TokenMinted(msg.sender, tokenId, _tokenType);
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        // update the bonus shares of the staking pool
        if (stakingPoolAddress != address(0)) {
            IStakingPool(stakingPoolAddress).updateBoostNftBonusShares(from, to, firstTokenId);
        }
    }

    /** Roles */

    function burn(uint256 tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
        tokenTypeSupply[tokenIdToType[tokenId]]--;
    }

    function setStakingPool(address _stakingPoolAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakingPoolAddress = _stakingPoolAddress;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param _myBaseUri the base URI string
     */
    function setBaseURI(string calldata _myBaseUri) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseURI = _myBaseUri;
    }

    /**
     * @dev set the price to mint one token
     * @param _legendaryPrice price of the legendary token
     * @param _collectorPrice price of the collector token
     */
    function setPrices(uint256 _legendaryPrice, uint256 _collectorPrice) external onlyRole(DEFAULT_ADMIN_ROLE) {
        tokenTypePrice[TokenType.Legendary] = _legendaryPrice;
        tokenTypePrice[TokenType.Collector] = _collectorPrice;
    }

    /** VIEW */

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return string(abi.encodePacked(baseURI, (tokenId % MAX_ART_COUNT).toString(), ".json"));
    }
}
