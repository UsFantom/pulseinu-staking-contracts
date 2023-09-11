// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "hardhat/console.sol";

import "./interfaces/IPulseInu.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title PulseInu
/// @author Bounyavong
/// @dev PulseInu is a simple ERC20 token
contract PulseInu is IPulseInu, ERC20, ReentrancyGuard {
    // a mapping claimer address to claimed status
    mapping(address => uint256) public claimed;
    /**
     * This value is binary
     * 001 -> FreeClaimer Claimed
     * 010 -> Referrer Claimed
     * 100 -> First Adopter Claimed
     */

    // contract info
    ContractInfo public contractInfo;

    // initial supply in mint phase
    uint256 public INITIAL_SUPPLY;

    // owner address of the contract
    address public constant OWNER_ADDRESS =
        0x81a9ca8482E9a4b05aFE23Bd5BBEE0f4F7E746d0;

    bytes32 private constant claimerMerkleRoot =
        0x0435274178c61a6ac38e6bdb4ef8ea96136b7a51c5c63ab58f3b8331f521cbbd; // the merkle tree root of the claimer address list
    bytes32 private constant referrerMerkleRoot =
        0x41ec9f6040b37ed056c20cd83c2f657f5fddd7beb333c8275134ab99d5f591e1; // the merkle tree root of the referrer (address + percent) list
    bytes32 private constant firstAdopterMerkleRoot =
        0x86ca269580aeb0d6bed18fe274240b9981312fca19f27ad7dc33ab861f76fc80; // the merkle tree root of the message sender address list

    uint256 public countClaims;

    /** events */
    event Claimed(address indexed claimer, uint256 indexed amount);
    event Minted(address indexed minter, uint256 indexed amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _airdropDuration,
        uint256 _mintDuration,
        uint256 _firstAdopterPercent,
        uint256 _referrerPercent,
        uint256 _price,
        uint256 _airdropAmount
    ) ERC20(_name, _symbol) {
        contractInfo = ContractInfo(
            uint128(block.timestamp + _airdropDuration), // airdrop end time
            uint128(block.timestamp + _mintDuration), // mint end time
            uint32(_firstAdopterPercent), // percent of initial supply for each first adopter address
            uint32(_referrerPercent), // percent of the initial supply for whole the referrers
            uint32(_price), // price per PINU wei
            uint32(_airdropAmount) // airdrop amount without decimals
        );
    }

    /** USER */

    /**
     * @dev PUBLIC FUNCTION: External function to claim airdrop tokens. Must be before the end of the claim phase.
     * Tokens can only be minted once per unique address. The address must be within the airdrop set.
     * @param proof containing sibling hashes on the branch from the leaf to the root of the tree
     */
    function claimFreeClaimer(
        bytes32[] memory proof
    ) external inAirdropTimeWindow {
        require(
            MerkleProof.verify(
                proof,
                claimerMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "NOT_AIRDROP_CLAIMABLE_ADDR"
        );

        INITIAL_SUPPLY += contractInfo.airdropAmount * (10 ** decimals());
        _claimTokens(
            _msgSender(),
            contractInfo.airdropAmount * (10 ** decimals()),
            0x01
        );
    }

    /**
     * @dev PUBLIC FUNCTION: External function to claim tokens for refferer. Must be after the end of the mint phase.
     * Tokens can only be minted once per unique address. The address must be within the referrer set.
     * @param proof containing sibling hashes on the branch from the leaf to the root of the tree
     */
    function claimReferrer(
        bytes32[] memory proof,
        uint256 eachPercent
    ) external outMintTimeWindow {
        require(
            MerkleProof.verify(
                proof,
                referrerMerkleRoot,
                keccak256(abi.encodePacked(_msgSender(), eachPercent))
            ),
            "NOT_REFERRER_CLAIMABLE_ADDR_PERCENT"
        );

        _claimTokens(
            _msgSender(),
            ((INITIAL_SUPPLY * contractInfo.referrerPercent * eachPercent) /
                1e8),
            0x02
        );
    }

    /**
     * @dev PUBLIC FUNCTION: External function to claim tokens for first adopter. Must be after the end of the mint phase.
     * Tokens can only be minted once per unique address. The address must be within the first adopter set.
     * @param proof containing sibling hashes on the branch from the leaf to the root of the tree
     */
    function claimFirstAdopter(
        bytes32[] memory proof
    ) external outMintTimeWindow {
        require(
            MerkleProof.verify(
                proof,
                firstAdopterMerkleRoot,
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "NOT_FIRST_ADOPTER_CLAIMABLE_ADDR"
        );

        _claimTokens(
            _msgSender(),
            ((INITIAL_SUPPLY * contractInfo.firstAdopterPercent) / 1000000),
            0x04
        );
    }

    /**
     * @dev PRIVATE FUNCTION: Internal function to claim tokens.
     * @param to claimer address
     * @param amount PINU amout to claim
     */
    function _claimTokens(
        address to,
        uint256 amount,
        uint256 claimedFlag
    ) private nonReentrant {
        require((claimed[to] & claimedFlag) == 0, "ALREADY_CLAIMED");
        claimed[_msgSender()] |= claimedFlag;

        // Increment the number of claims counter
        countClaims++;

        // Mint tokens to address
        _mint(to, amount); // mint PINU amount to the caller

        // Emit claim event
        emit Claimed(to, amount);
    }

    /**
     * @dev mint PINU token
     */
    function mint() external payable inMintTimeWindow nonReentrant {
        require(msg.value > contractInfo.pricePINU, "AT_LEAST_1_PINU");

        // TODO: calculate the PINU amount from the price
        uint256 _amount = msg.value / contractInfo.pricePINU;

        // Mint token to buyer
        _mint(_msgSender(), _amount);
        INITIAL_SUPPLY += _amount;

        emit Minted(_msgSender(), _amount);
    }

    /**
     * @dev withdraw the PLS after mint phase
     */
    function withdraw() external outMintTimeWindow {
        require(_msgSender() == OWNER_ADDRESS, "NOT_OWNER");
        transferETH(payable(_msgSender()), address(this).balance);
    }

    /** VIEW */

    /**
     * @dev PUBLIC FUNCTION: Overridden decimals function
     * @return token decimals
     */
    function decimals() public pure override returns (uint8) {
        return 12;
    }

    function transferETH(address payable to, uint256 amount) private {
        uint256 startGas = gasleft();
        console.log("startGas:", startGas); // Log the value of startGas to the console
        (bool success, ) = to.call{value: amount, gas: startGas}("");
        require(success, "FAILED_TRANSFER");
    }

    /** MODIFIER */

    modifier inAirdropTimeWindow() {
        require(
            block.timestamp <= contractInfo.airdropEndTime,
            "AIRDROP_TIMEOUT"
        );
        _;
    }

    modifier inMintTimeWindow() {
        require(block.timestamp <= contractInfo.mintEndTime, "MINT_TIMEOUT");
        _;
    }

    modifier outMintTimeWindow() {
        require(block.timestamp > contractInfo.mintEndTime, "MINT_TIMEIN");
        _;
    }
}
