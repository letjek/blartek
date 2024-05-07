// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "./base_erc20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract baseITO is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    BaseERC20 public token;
    BaseERC20 public specialToken;
    address public currency;
    uint256 public fee;
    bool isAutoList;
    bool public isWhitelist;
    uint256 public presaleRate;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public minBuy;
    uint256 public maxBuy;
    RefundType public refundType;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public specialStartTime;
    uint256 public alreadyRaised;
    uint256 public alreadyClaimed;
    // Release public released;

    mapping(address => UserInfo) public usersTokenBought;
    mapping(address => bool) public whitelisted;

    struct UserInfo {
        uint256 totalToken;
        uint256 totalSpent;
        uint256 totalSpecialSpent;
    }

    enum RefundType {
        Burn,
        Refund
    }

    // enum Release {
    //     NOT_SET,
    //     FAILED,
    //     RELEASED
    // }

    // enum Claims {
    //     FULL,
    //     FAILED
    // }

    struct Data {
        address token;
        address specialToken;
        address currency;
        uint256 fee;
        bool isAutoList;
        bool isWhitelist;
        uint256 presaleRate;
        uint256 softCap;
        uint256 hardCap;
        uint256 minBuy;
        uint256 maxBuy;
        RefundType refundType;
    }

    modifier onlyActiveWhitelist() {
        require(isWhitelist, "Whitelist system not active");
        _;
    }

    modifier withdrawCheck() {
        require(getHardFilled() || (block.timestamp > endTime && getSoftFilled()), "Can't withdraw");
        _;
    }

    constructor(Data memory data) Ownable(msg.sender) {
        require(data.hardCap.mul(25).div(100) < data.softCap && data.hardCap > data.softCap, "Hardcap must greater than softcap 25%");
        token = BaseERC20(data.token);
        specialToken = BaseERC20(data.specialToken);
        currency = data.currency;
        isAutoList = data.isAutoList;
        isWhitelist = data.isWhitelist;
        presaleRate = data.presaleRate;
        softCap = data.softCap;
        hardCap = data.hardCap;
        minBuy = data.minBuy;
        maxBuy = data.maxBuy;
        refundType = data.refundType;
    }

    function setWhiteList(address whitelisted_)
        public
        onlyOwner
        onlyActiveWhitelist
    {
        require(!whitelisted[whitelisted_], "Already whitelisted");
        whitelisted[whitelisted_] = true;
    }

    function deleteWhiteList(address whitelisted_)
        public
        onlyOwner
        onlyActiveWhitelist
    {
        require(whitelisted[whitelisted_], "Not whitelisted");
        whitelisted[whitelisted_] = false;
    }

    function setRaised(
        uint256 startTime_, uint256 endTime_, uint256 specialStartTime_
    ) public onlyOwner nonReentrant {
        require(startTime_ != 0, "Must set correct time");
        require(specialStartTime_ < startTime_, "Raising has started");
        require(startTime_ > block.timestamp, "Must not yet started");
        require(endTime_ > startTime_, "End time must be greater than start");
        startTime = startTime_;
        endTime = endTime_;
        specialStartTime = specialStartTime_;
        uint256 totalTokenSale_ = hardCap.mul(presaleRate);
        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balance = token.balanceOf(msg.sender);
        require(allowance >= totalTokenSale_, "Check the token allowance");
        require(balance >= totalTokenSale_, "Not enough tokens");

        token.transferFrom(msg.sender, address(this), totalTokenSale_);
    }

    function getHardFilled() public view returns (bool) {
        return alreadyRaised >= hardCap;
    }

    function getSoftFilled() public view returns (bool) {
        return alreadyRaised >= softCap;
    }

    function getSellTokenAmount(uint256 amount_)
        internal
        view
        returns (uint256)
    {
        return amount_.mul(presaleRate);
    }

    function buy() external payable nonReentrant {
        if (isWhitelist) {
            require(whitelisted[msg.sender] || (specialToken != BaseERC20(address(0)) && specialToken.balanceOf(msg.sender) > 0), "Not whitelisted");
        }
        require(block.timestamp != 0, "Raising period not set");
        require(block.timestamp >= startTime, "Raising period not started yet");
        require(block.timestamp < endTime, "Raising period already end");
        require(msg.value > 0, "Please input value");
        require(getHardFilled() == false, "Raise already fullfilled");

        UserInfo memory userInfo = usersTokenBought[msg.sender];

        require(userInfo.totalSpent.add(msg.value) >= minBuy, "Less than min buy");
        require(userInfo.totalSpent.add(msg.value) <= maxBuy, "More than max buy");
        require(
            msg.value + alreadyRaised <= hardCap,
            "Amount buy more than total hardcap"
        );

        uint256 tokenSellAmount = getSellTokenAmount(msg.value);
        userInfo.totalToken = userInfo.totalToken.add(tokenSellAmount);
        userInfo.totalSpent = userInfo.totalSpent.add(msg.value);
        usersTokenBought[msg.sender] = userInfo;

        alreadyRaised = alreadyRaised.add(msg.value);
    }

    function claimFailed() external nonReentrant {
        require(block.timestamp > endTime, "Raising not end");
        require(getSoftFilled() == false, "Soft cap already fullfiled");

        uint256 userSpent = usersTokenBought[msg.sender].totalSpent;
        uint256 userSpecialSpent = usersTokenBought[msg.sender].totalSpecialSpent;
        require(userSpent > 0, "Already claimed");

        payable(msg.sender).transfer(userSpent.add(userSpecialSpent));

        delete usersTokenBought[msg.sender];
    }

    function claimSuccess()
        external nonReentrant
    {
        if (!getHardFilled()) {
            require(block.timestamp > endTime, "Raising not end");
            require(getSoftFilled(), "Soft cap not fullfiled");
        }      
        UserInfo storage userInfo = usersTokenBought[msg.sender];
        require(userInfo.totalToken > 0, "You can't claim any amount");

        usersTokenBought[msg.sender] = userInfo;
        token.transfer(msg.sender, userInfo.totalToken);
        alreadyClaimed = alreadyClaimed.add(userInfo.totalToken);

        delete usersTokenBought[msg.sender];
    }

    function specialBuy() external payable nonReentrant {
        require((specialToken != BaseERC20(address(0)) && specialToken.balanceOf(msg.sender) > 0), "Not whitelisted");
        require(specialStartTime != 0, "Raising special period not set");
        require(block.timestamp < startTime, "Special period has ended");
        require(msg.value > 0, "Please input value");
        require(getHardFilled() == false, "Raise already fullfilled");

        UserInfo memory userInfo = usersTokenBought[msg.sender];

        // uint256 specialUserBalance = specialToken.balanceOf(msg.sender);

        require(userInfo.totalSpecialSpent.add(msg.value) >= minBuy, "Less than min buy");
        require(userInfo.totalSpecialSpent.add(msg.value) <= maxBuy, "More than max buy");
        require(
            msg.value + alreadyRaised <= hardCap,
            "Amount buy more than total hardcap"
        );

        uint256 tokenSellAmount = getSellTokenAmount(msg.value);
        userInfo.totalToken = userInfo.totalToken.add(tokenSellAmount);
        userInfo.totalSpecialSpent = userInfo.totalSpecialSpent.add(msg.value);
        usersTokenBought[msg.sender] = userInfo;

        alreadyRaised = alreadyRaised.add(msg.value);
    }

    function endProcess() public onlyOwner nonReentrant {
        // require(block.timestamp > endTime && !getHardFilled(), "Raising not end with failed state");
        require(alreadyClaimed == alreadyRaised.mul(presaleRate), "Claim not end");
        if (refundType == RefundType.Burn) {
            token.burn(hardCap.mul(presaleRate).sub(alreadyClaimed));
            alreadyClaimed = 0;
        } 
        if (refundType == RefundType.Refund) {
            token.transfer(owner(), hardCap.mul(presaleRate).sub(alreadyClaimed));
            alreadyClaimed = 0;
        } 
    }

    function withdrawRaised() public onlyOwner withdrawCheck {
        uint256 balance = address(this).balance;
        require(balance > 0, "Does not have any balance");
        payable(msg.sender).transfer(balance);
    }

}