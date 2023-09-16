// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPulseXRouter02 } from "./interface/IPulseXRouter02.sol";

contract PinuSwapBurner {
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant PULSE_X_ROUTER_02 = 0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02;
    address public constant PINU_TOKEN = 0xa12E2661ec6603CBbB891072b2Ad5b3d5edb48bd;

    event BurnedPLS(uint256 indexed plsAmount, uint256 indexed pinuAmount);

    function _swapPlsToPinu(uint256 plsAmount) private {
        address[] memory path = new address[](2);
        path[0] = IPulseXRouter02(PULSE_X_ROUTER_02).WPLS();
        path[1] = PINU_TOKEN;
        IPulseXRouter02(PULSE_X_ROUTER_02).swapExactETHForTokens{ value: plsAmount }(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _burnPls(uint256 amount) private {
        uint256 initialPinuBalance = IERC20(PINU_TOKEN).balanceOf(address(this));
        _swapPlsToPinu(amount);
        uint256 newPinuBalance = IERC20(PINU_TOKEN).balanceOf(address(this));
        uint256 pinuSwapped = newPinuBalance - initialPinuBalance;
        IERC20(PINU_TOKEN).transfer(BURN_ADDRESS, pinuSwapped);
        emit BurnedPLS(amount, pinuSwapped);
    }

    function burnPLS() external payable {
        _burnPls(msg.value);
    }
}
