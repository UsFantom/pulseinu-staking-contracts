// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IBoostNft {
    enum TokenType {
        Legendary,
        Collector
    }

    function tokenIdToType(uint256 tokenId) external view returns (TokenType);

    function getBalancesByTokenType(address _address) external view returns (uint256, uint256);
}
