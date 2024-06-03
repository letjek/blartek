// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseERC20 is ERC20, Ownable {
    address public immutable fund;
    uint256 public tax;

    constructor(
        address owner_,
        string memory name,
        string memory symbol,
        uint256 totalSupply,
        address fund_,
        uint256 tax_
    ) ERC20(name, symbol) Ownable(owner_) {
        fund = fund_;
        tax = tax_;
        _mint(owner_, totalSupply);
    }

    function setTax(uint256 newTax) public onlyOwner {
        tax = newTax;
    }

    function _update(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        uint256 tax_ = (amount / 100) * tax; // 5% tax

        if (sender == address(0) || recipient == address(0)) {
            super._update(sender, recipient, amount);
            return;
        }

        super._update(sender, recipient, amount - tax_);
        super._update(sender, fund, tax_);
    }
}