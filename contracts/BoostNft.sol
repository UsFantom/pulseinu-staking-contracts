// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ERC721, ERC721Enumerable, Strings } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title PulseInuNft
/// @author Bounyavong
/// @dev PulseInuNft is a ERC721 standard NFT
contract PulseInuNft is ERC2981, ERC721Enumerable, Ownable {
    using Strings for uint256;

    // the last tokenId that was minted already
    uint256 public minted;
    uint256 public maxSupply;
    uint256 public price;
    // Base URI for each token
    string public baseURI;
    // a mapping from an address to whether or not it can mint
    mapping(address => bool) public controllers;

    // a mapping from a token Id to a level
    mapping(uint256 => uint256) public levels;

    /** EVENT */

    // emit when the level of a token has been set or changed.
    event TokenLevelSet(uint256 indexed tokenId, uint256 indexed level);
    // emit when the default royalty has been set or changed.
    event DefaultRoyaltySet(address indexed recipient, uint96 indexed feeNumerator);
    // emit when the royalty of a token has been set or changed.
    event TokenRoyaltySet(uint256 indexed tokenId, address indexed recipient, uint96 indexed feeNumerator);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _myBaseUri,
        uint256 _maxSupply,
        address defaultRoyaltyReceiver,
        uint96 feeNumerator,
        uint256 _price
    ) ERC721(_name, _symbol) {
        baseURI = _myBaseUri;
        _setDefaultRoyalty(defaultRoyaltyReceiver, feeNumerator);
        controllers[_msgSender()] = true;
        maxSupply = _maxSupply;
        price = _price;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /** PRIVATE */

    /**
     * @dev send funds to an address
     * @param to the address to receive the funds
     * @param amount the amount of the funds
     */
    function _safeTransferFunds(address to, uint256 amount) private returns (bool) {
        (bool success, ) = payable(to).call{ value: amount, gas: 21000 }("");
        return success;
    }

    /** USER */

    /**
     * @dev mint a token
     * @param numTokens the number of the token
     */
    function mint(uint256 numTokens) external payable {
        require(minted + numTokens <= maxSupply, "max supply");
        require(numTokens > 0, "Min 1");
        require(numTokens <= 10, "Max 10");

        require(msg.value == price * numTokens, "Insufficient Amount");
        require(_safeTransferFunds(owner(), msg.value), "FAILED_OWNER_TRANSFER");

        for (uint256 i = 0; i < numTokens; i++) {
            if (minted < 10) {
                levels[minted] = 3;
            } else if (minted < 1000) {
                levels[minted] = 2;
            } else {
                levels[minted] = 1;
            }
            _safeMint(_msgSender(), minted++);
        }
    }

    /** CONTROLLER */

    /**
     * @dev set a level of a token
     * @param tokenId the token Id
     * @param _level new level value
     */
    function setTokenLevel(uint256 tokenId, uint256 _level) external onlyController {
        levels[tokenId] = _level;
        emit TokenLevelSet(tokenId, _level);
    }

    /** ADMIN */

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     * @param _myBaseUri the base URI string
     */
    function setBaseURI(string calldata _myBaseUri) external onlyOwner {
        baseURI = _myBaseUri;
    }

    /**
     * @dev set the price to mint one token
     * @param _price the new price
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @dev enables an address to mint
     * @param _controller the address to enable
     */
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /**
     * @dev disables an address from minting
     * @param _controller the address to disbale
     */
    function removeController(address _controller) external onlyOwner {
        delete controllers[_controller];
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _deleteDefaultRoyalty();
        _setDefaultRoyalty(receiver, feeNumerator);

        emit DefaultRoyaltySet(receiver, feeNumerator);
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltySet(tokenId, receiver, feeNumerator);
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

    /** MODIFIER */

    modifier onlyController() {
        require(controllers[_msgSender()] == true, "ONLY_CONTROLLER");
        _;
    }
}
