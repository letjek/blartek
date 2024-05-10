// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseERC20 is IERC20, ERC20Burnable, Ownable {
    address public immutable fund;
    uint256 public tax;

    constructor(
        address initialOwner,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address fund_,
        uint256 tax_
    ) ERC20(name, symbol) Ownable(initialOwner) {
        mint(initialOwner, totalSupply);
        fund = fund_;
        tax = tax_;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function setTax(uint256 newTax) public onlyOwner {
        tax = newTax;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        uint256 tax_ = (amount / 100) * tax; // 5% tax

        super._transfer(sender, recipient, amount - tax_);
        super._transfer(sender, fund, tax_);
    }
}