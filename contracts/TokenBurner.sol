// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenBurner {
    using SafeERC20 for IERC20;

    IERC20 public immutable _token;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    event TokensBurned(address indexed burner, uint256 amount);

    constructor(address tokenAddress) {
        _token = IERC20(tokenAddress);
    }

    function burnTokens() external {
        uint256 amount = _token.balanceOf(address(this));
        _token.transfer(BURN_ADDRESS, amount);
        emit TokensBurned(msg.sender, amount);
    }
}
