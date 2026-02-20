// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShareToken is ERC20 {
    address public VAULT;

    error SharesNonTransferable();
    error OnlyVault();
    error ZeroAddress();
    error VaultAlreadySet();

    event VaultSet(address indexed vault);

    /// @notice Deploy ShareToken, vault address can be set once after deployment
    constructor() ERC20("Vault Share Token", "vSHARE") {}

    /// @notice Set the vault address (can only be called once)
    /// @param _vault The vault contract address
    function setVault(address _vault) external {
        if (VAULT != address(0)) revert VaultAlreadySet();
        if (_vault == address(0)) revert ZeroAddress();
        VAULT = _vault;
        emit VaultSet(_vault);
    }

    /// @param to Recipient of minted shares
    /// @param amount Number of shares to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != VAULT) revert OnlyVault();
        _mint(to, amount);
    }

    /// @param from Address whose shares will be burned
    /// @param amount Number of shares to burn
    function burn(address from, uint256 amount) external {
        if (msg.sender != VAULT) revert OnlyVault();
        _burn(from, amount);
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert SharesNonTransferable();
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert SharesNonTransferable();
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert SharesNonTransferable();
    }

    function allowance(address, address) public pure override returns (uint256) {
        return 0;
    }
}
