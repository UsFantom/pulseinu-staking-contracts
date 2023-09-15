// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20
/// @author Bounyavong
/// @dev MockERC20 is a simple ERC20 token
contract MockERC20 is ERC20 {
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply) ERC20(_name, _symbol) {
        _mint(msg.sender, _initialSupply);
    }

    /**
     * @dev PUBLIC FUNCTION: Overridden decimals function
     * @return token decimals
     */
    function decimals() public pure override returns (uint8) {
        return 12;
    }
}
