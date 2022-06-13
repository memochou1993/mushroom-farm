// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MushroomFarm {
    uint constant PERIOD = 864000;
    uint public marketMushrooms;
    uint public startTime = 2000000000;
    address public owner;
    mapping (address => uint) private lastHarvest;
    mapping (address => uint) private farmers;
    mapping (address => uint) private claimedMushrooms;
    mapping (address => uint) private tempClaimedMushrooms;
    mapping (address => address) private referrals;
    mapping (address => ReferralData) private referralData;

    struct ReferralData {
        address[] invitees;
        uint rebates;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    modifier onlyInitialize {
        require(marketMushrooms > 0, "not initialized");
        _;
    }

    modifier onlyOpen {
        require(block.timestamp > startTime, "not opened");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function initialize(uint _startTime) external payable onlyOwner {
        require(marketMushrooms == 0);
        startTime = _startTime;
        marketMushrooms = 86400000000;
    }

    function buyMushrooms(address _ref) external payable onlyInitialize {
        uint mushroomValue = calculateMushroomBuy(msg.value, address(this).balance - msg.value);
        mushroomValue -= getDevFee(mushroomValue);
        uint fee = getDevFee(msg.value);
        payable(owner).transfer(fee);
        claimedMushrooms[msg.sender] += mushroomValue;
        multiplyMushrooms(_ref);
    }

    function multiplyMushrooms(address _ref) public onlyInitialize {
        if (_ref == msg.sender || _ref == address(0) || farmers[_ref] == 0) {
            _ref = owner;
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
            referralData[_ref].invitees.push(msg.sender);
        }
        uint mushroomUsed = getMushrooms(msg.sender);
        uint newBreeders = mushroomUsed / PERIOD;
        farmers[msg.sender] += newBreeders;
        claimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp > startTime ? block.timestamp : startTime;
        uint mushroomRebate = mushroomUsed * 15 / 100;
        if (referrals[msg.sender] == owner) {
            claimedMushrooms[owner] += mushroomRebate;
            tempClaimedMushrooms[owner] += mushroomRebate;
        } else {
            claimedMushrooms[referrals[msg.sender]] += mushroomRebate;
            tempClaimedMushrooms[referrals[msg.sender]] += mushroomRebate;
        }
        marketMushrooms += mushroomUsed / 5;
    }

    function sellMushrooms() public onlyOpen {
        uint myMushrooms = getMushrooms(msg.sender);
        uint mushroomValue = calculateMushroomSell(myMushrooms);
        uint fee = getDevFee(mushroomValue);
        uint realReward = mushroomValue - fee;
        if (tempClaimedMushrooms[msg.sender] > 0) {
            referralData[msg.sender].rebates += calculateMushroomSell(tempClaimedMushrooms[msg.sender]);
        }
        payable(owner).transfer(fee);
        claimedMushrooms[msg.sender] = 0;
        tempClaimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketMushrooms += myMushrooms;
        payable(msg.sender).transfer(realReward);
    }

    function getRewards(address _address) public view returns (uint) {
        return calculateMushroomSell(getMushrooms(_address));
    }

    function getMushrooms(address _address) public view returns (uint) {
        return claimedMushrooms[_address] + getMushroomsSinceLastMultiply(_address);
    }

    function getClaimedMushrooms(address _address) public view returns (uint) {
        return claimedMushrooms[_address];
    }

    function getMushroomsSinceLastMultiply(address _address) public view returns (uint) {
        if (block.timestamp > startTime) {
            uint secondsPassed = min(PERIOD, block.timestamp - lastHarvest[_address]);
            return secondsPassed * farmers[_address];
        } else {
            return 0;
        }
    }

    function getTempClaimedMushrooms(address _address) public view returns (uint) {
        return tempClaimedMushrooms[_address];
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getFarmers(address _address) public view returns (uint) {
        return farmers[_address];
    }

    function getReferralData(address _address) public view returns (ReferralData memory) {
        return referralData[_address];
    }

    function getReferralRebates(address _address) public view returns (uint) {
        return referralData[_address].rebates;
    }

    function getReferralInviteeCount(address _address) public view returns (uint) {
        return referralData[_address].invitees.length;
    }

    function calculateMushroomBuy(uint _amount, uint _contractBalance) private view returns (uint) {
        return calculateTrade(_amount, _contractBalance, marketMushrooms);
    }

    function calculateMushroomSell(uint _count) private view returns (uint) {
        return calculateTrade(_count, marketMushrooms, address(this).balance);
    }

    function calculateTrade(uint256 _rt,uint256 _rs, uint256 _bs) private pure returns (uint) {
        uint256 psn = 10000;
        uint256 psnh = 5000;
        return (psn * _bs) / (psnh + ((psn * _rs + psnh * _rt) / _rt));
    }

    function getDevFee(uint _amount) private pure returns (uint) {
        return _amount * 2 / 100;
    }

    function min(uint _a, uint _b) private pure returns (uint) {
        return _a < _b ? _a : _b;
    }
}
