// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mushroom {
    bool public initialized = false;
    uint256 public period = 86400 * 10;
    uint256 public marketMushroom;
    address public owner;
    mapping (address => uint256) public miners;
    mapping (address => uint256) public claimedMushrooms;
    mapping (address => uint256) public lastHarvest;
    mapping (address => address) public referrals;

    constructor() {
        owner = msg.sender;
    }

    function initialize() public {
        require(msg.sender == owner);
        require(marketMushroom == 0);
        initialized = true;
        marketMushroom = 86400 * 1000000;
    }

    function buyMushrooms(address _ref) public payable {
        require(initialized);
        uint256 value = calculate(msg.value, address(this).balance - msg.value, marketMushroom);
        value -= getDevFee(value);
        uint256 fee = getDevFee(msg.value);
        payable(owner).transfer(fee);
        claimedMushrooms[msg.sender] += value;
        splitMushrooms(_ref);
    }

    function splitMushrooms(address _ref) public {
        require(initialized);
        if (_ref == msg.sender || _ref == address(0) || miners[_ref] == 0) {
            _ref = owner;
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = _ref;
        }
        uint256 used = getMyMushrooms();
        miners[msg.sender] += used / period;
        claimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        claimedMushrooms[referrals[msg.sender]] += used * 13 / 100;
        marketMushroom += used / 5;
    }

    function sellMushrooms() public {
        require(initialized);
        uint256 myMushrooms = getMyMushrooms();
        uint256 value = calculate(myMushrooms, marketMushroom, address(this).balance);
        uint256 fee = getDevFee(value);
        claimedMushrooms[msg.sender] = 0;
        lastHarvest[msg.sender] = block.timestamp;
        marketMushroom += myMushrooms;
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

    function getMyMiners() public view returns (uint256) {
        return miners[msg.sender];
    }

    function getMyMushrooms() public view returns (uint256) {
        return claimedMushrooms[msg.sender] + getMushroomsSinceLastHarvest(msg.sender);
    }

    function getMushroomsSinceLastHarvest(address _address) public view returns (uint256) {
        return min(period, block.timestamp - lastHarvest[_address]) * miners[_address];
    }

    function min(uint256 _a, uint256 _b) private pure returns (uint256) {
        return _a < _b ? _a : _b;
    }
}
