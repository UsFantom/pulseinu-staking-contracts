// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IPulseInuToken } from "./interface/IPulseInuToken.sol";

/**
 * @title PulseInuMint
 * @author Bounyavong
 * @dev PulseInuMint is a contract that mints PINU ERC20 tokens to the caller who is paying the cost of the token
 */
contract PulseInuMint is Ownable, Pausable, ReentrancyGuard {
    // PINU token price by BNB
    uint256 public tokenPrice;

    /**
     * @dev Address of the PulseInuToken ERC20 contract
     */
    address public pinuTokenAddress;

    /**
     * @dev Initializes the contract by setting the PINU ERC20 contract address
     * @param _addressPINU PINU ERC20 contract address
     * @param _tokenPrice PINU ERC20 token price by BNB
     */
    constructor(address _addressPINU, uint256 _tokenPrice) {
        pinuTokenAddress = _addressPINU;
        tokenPrice = _tokenPrice;
    }

    /** ADMIN */

    /**
     * @dev Pause or unpause the contract features
     */
    function setPause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /**
     * @dev Set the PINU token price by BNB
     * @param _tokenPrice PINU token price
     */
    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    /**
     * @dev withdraw the balance of the contract
     */
    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    /** USER */

    /**
     * @dev Mints PINU ERC20 tokens to the caller's address
     * @param amount PINU ERC20 token amount
     */
    function mint(uint256 amount) external payable whenNotPaused nonReentrant {
        require(msg.value == (tokenPrice * amount) / 1e18, "PulseInuMint: mint(): paid amount is not correct");
        IPulseInuToken(pinuTokenAddress).mint(_msgSender(), amount);
    }
}
