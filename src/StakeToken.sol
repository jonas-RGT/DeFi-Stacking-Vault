// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract StakeToken is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Stake Token", "STAKE") Ownable(initialOwner) {}

    /// @param to Recipient of minted tokens
    /// @param amount Number of tokens to mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
