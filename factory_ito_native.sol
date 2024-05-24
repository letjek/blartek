// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./factory_erc20.sol";
import "./base_ito_native.sol";

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
    
    function createNativeITO(address token, DataCommon calldata data, BaseITONative.RefundType refundType) public returns (address) {
        BaseITONative.DataNative memory inputData;
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
        BaseITONative itoContract_ = new BaseITONative(inputData);
        return address(itoContract_);
    }

    function deployNewTokenAndCreateNativeITO(
        string calldata name,
        string calldata symbol,
        uint256 totalSupply,
        address fund,
        uint256 tax,
        DataCommon calldata data,
        BaseITONative.RefundType refundType
    ) public returns (address, address) {
        address newTokenAddress = factoryERC20.deployNewERC20Token(name, symbol, totalSupply, fund, tax);
        address itoContractAddress = createNativeITO(newTokenAddress, data, refundType);
        return (newTokenAddress, itoContractAddress);
    }
}