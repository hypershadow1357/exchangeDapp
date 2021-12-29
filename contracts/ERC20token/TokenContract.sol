// SPDX-License-Identifier: Thinh
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenContract is
    AccessControlEnumerable,
    ERC20Burnable,
    ERC20Pausable,
    ERC20Capped
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        ERC20Capped(100000000 * 10**18)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function mint (address to_, uint256 amount_) public{
        require(
            hasRole(MINTER_ROLE, _msgSender()),
            "Token: must have minter role to mint"
        );
        require(amount_ > 0, "mint: Invalid amount");
        _mint(to_, amount_);
    }

    function _mint(address account, uint256 amount)
        internal
        override(ERC20, ERC20Capped)
    {
        ERC20Capped._mint(account, amount);
    }

    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to pause"
        );
        _pause();
    }

    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "Token: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        ERC20Pausable._beforeTokenTransfer(from, to, amount);
    }

}