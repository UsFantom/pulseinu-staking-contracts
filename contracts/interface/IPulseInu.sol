// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IPulseInu {
    // Struct for Contract Info
    struct ContractInfo {
        uint128 airdropEndTime; // airdrop end time
        uint128 mintEndTime; // mint end time
        uint32 firstAdopterPercent; // 1,000,000 = 100%
        uint32 referrerPercent; // 10,000 = 100%
        uint32 pricePINU; // PLS amount per PINU wei
        uint32 airdropAmount; // PINU amount without decimals
    }

    /**
     * @dev mint PINU token
     */
    function mint() external payable;
}
