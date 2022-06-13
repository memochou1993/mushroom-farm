// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mushroom {
    address public owner;
    uint256 public period = 864000;
    uint256 public startTime = 2000000000;
    uint256 public marketMushrooms;
    mapping (address => uint256) public farmers;
    mapping (address => uint256) public claimedMushrooms;
    mapping (address => uint256) public lastHarvest;
    mapping (address => address) public referrals;

    modifier onlyOwner {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    modifier onlyInitialized {
        require(marketMushrooms > 0, "not initialized");
        _;
    }

    modifier onlyStarted {
        require(block.timestamp > startTime, "not started");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function initialize(uint _startTime) onlyOwner public {
        require(marketMushrooms == 0, "already initialized");
        startTime = _startTime;
        marketMushrooms = 86400000000;
    }

    function buyMushrooms(address _ref) onlyInitialized public payable {
        uint256 value = calculate(msg.value, address(this).balance - msg.value, marketMushrooms);
        value -= getDevFee(value);
        uint256 fee = getDevFee(msg.value);
        payable(owner).transfer(fee);
        claimedMushrooms[msg.sender] += value;
        multiplyMushrooms(_ref);
    }

    function multiplyMushrooms(address _ref) onlyInitialized public {
        if (_ref == msg.sender || _ref == address(0) || farmers[_ref] == 0) {
            _ref = owner;
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
        }
        uint256 used = getMyMushrooms();
        uint256 newFarmers = used / period;
        farmers[msg.sender] += newFarmers;
        claimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        claimedMushrooms[referrals[msg.sender]] += used * 15 / 100;
        marketMushrooms += used / 5;
    }

    function sellMushrooms() onlyStarted public {
        uint256 myMushrooms = getMyMushrooms();
        uint256 value = calculate(myMushrooms, marketMushrooms, address(this).balance);
        uint256 fee = getDevFee(value);
        claimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketMushrooms += myMushrooms;
        payable(owner).transfer(fee);
        payable(msg.sender).transfer(value - fee);
    }

    function calculate(uint256 _rt, uint256 _rs, uint256 _bs) public pure returns (uint256) {
        uint256 psn = 10000;
        uint256 psnh = 5000;
        return (psn * _bs) / (psnh + ((psn * _rs + psnh * _rt) / _rt));
    }

    function getDevFee(uint256 _amount) public pure returns (uint256) {
        return _amount * 3 / 100;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyFarmers() public view returns (uint256) {
        return farmers[msg.sender];
    }

    function getMyMushrooms() public view returns (uint256) {
        return claimedMushrooms[msg.sender] + getMushroomsSinceLastHarvest(msg.sender);
    }

    function getMushroomsSinceLastHarvest(address _address) public view returns (uint256) {
        return min(period, block.timestamp - lastHarvest[_address]) * farmers[_address];
    }

    function min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}
