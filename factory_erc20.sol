// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./base_erc20.sol";

contract FactoryERC20 is Ownable {
    
    constructor(
        address initialOwner
    ) Ownable(initialOwner) {}
    
    function deployNewERC20Token(
        string calldata name_,
        string calldata symbol_,
        uint256 totalSupply_,
        address fund_,
        uint256 tax_
    ) public returns (address) {
        BaseERC20 t = new BaseERC20(
            msg.sender,
            name_,
            symbol_,
            totalSupply_,
            fund_,
            tax_
        );
        return address(t);
    }
}
