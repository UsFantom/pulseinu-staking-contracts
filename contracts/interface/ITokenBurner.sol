// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface ITokenBurner {
    /**
     * @dev burn PINU token
     */
    function burnTokens() external payable;
}
