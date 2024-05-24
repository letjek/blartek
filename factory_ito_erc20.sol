// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./factory_erc20.sol";
import "./base_ito_erc20.sol";

contract ITO is Ownable {

    FactoryERC20 internal factoryERC20;

    struct DataCommon {
        address specialToken;
        bool isAutoList;
        bool isWhitelist;
        uint256 fee;
        uint256 presaleRate;
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 specialThreshold;
    }

    constructor(
        address initialOwner
    ) Ownable(initialOwner) {}
    
    function createERC20ITO(address baseToken, address token, DataCommon calldata data, BaseITOERC20.RefundType refundType) public {
        BaseITOERC20.DataERC20 memory inputData;
        inputData.baseToken = baseToken;
        inputData.token = token;
        inputData.specialToken = data.specialToken;
        inputData.isAutoList = data.isAutoList;
        inputData.isWhitelist = data.isWhitelist;
        inputData.fee = data.fee;
        inputData.presaleRate = data.presaleRate;
        inputData.softCap = data.softCap;
        inputData.hardCap = data.hardCap;
        inputData.minBuy = data.minBuy;
        inputData.maxBuy = data.maxBuy;
        inputData.specialThreshold = data.specialThreshold;
        inputData.refundType = refundType;
        new BaseITOERC20(inputData);
    }

    function deployNewTokenAndCreateERC20ITO(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        address fund,
        uint256 tax,
        address baseToken,
        DataCommon calldata data,
        BaseITOERC20.RefundType refundType
    ) public {
        address newTokenAddress = factoryERC20.deployNewERC20Token(name, symbol, totalSupply, fund, tax);
        createERC20ITO(baseToken, newTokenAddress, data, refundType);
    }
}