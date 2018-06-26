pragma solidity ^0.4.20;

import "./SafeMath.sol";

contract Spangel {

  uint bank;
  address creator;
  uint beggerCount;

  struct Begger {
    address owner;
    address resolver;
    bool completed;
    uint coinRaised;
    uint projected;
    uint ttl;
    bool alive;
    mapping(address => uint) givers;
  }

  mapping(bytes32 => Begger) public beggers;

  modifier isAlive(bytes32 _userName) {
    require(beggers[_userName].alive == true);
    _;
  }

  modifier isOwner(bytes32 _userName) {
    require(beggers[_userName].owner == msg.sender);
    _;
  }

  modifier isNew(bytes32 _userName) {
    require(beggers[_userName].completed == false);
    _;
  }

  modifier isExpired(bytes32 _userName) {
    require(beggers[_userName].ttl >= now);
    _;
  }

  modifier isGiver(bytes32 _userName) {
    require(beggers[_userName].givers[msg.sender] > 0);
    _;
  }

  constructor() public {
    bank = 0;
    creator = msg.sender;
    beggerCount = 0;
  }

  function createBegger(bytes32 _userName,uint ttl, uint _projected) public isNew(_userName) {
    beggers[_userName].completed = false;
    beggers[_userName].coinRaised = 0;
    beggers[_userName].ttl = SafeMath.add(ttl, now);
    beggers[_userName].projected = _projected;
    beggers[_userName].alive = true;
    beggers[_userName].owner = msg.sender;
    beggerCount++;
  }

  function addResolver(bytes32 _userName, address _resolver) public isOwner(_userName) isAlive(_userName) {
    beggers[_userName].resolver = _resolver;
  }

  function give(bytes32 _userName) public payable {
    require(msg.value < beggers[_userName].projected);
    beggers[_userName].coinRaised = SafeMath.add(beggers[_userName].coinRaised, SafeMath.div(msg.value, 200));
    bank = SafeMath.add(bank, msg.value);
    beggers[_userName].givers[msg.sender] = SafeMath.add(msg.value, beggers[_userName].givers[msg.sender]);

    if (beggers[_userName].coinRaised >= beggers[_userName].projected) {
      beggers[_userName].resolver.transfer(beggers[_userName].projected);
      msg.sender.transfer(SafeMath.sub(beggers[_userName].coinRaised, beggers[_userName].projected));
      bank = SafeMath.sub(bank, beggers[_userName].projected);
      bank = SafeMath.sub(bank, SafeMath.sub(beggers[_userName].coinRaised, beggers[_userName].projected));
      beggers[_userName].alive = false;
      beggers[_userName].completed = true;
    }

  }

  function refund(bytes32 _userName) public isGiver(_userName) isExpired(_userName) {
    uint owed;
    owed = beggers[_userName].givers[msg.sender];
    beggers[_userName].givers[msg.sender] = 0;
    bank = SafeMath.sub(bank, owed);
    beggers[_userName].coinRaised = SafeMath.sub(beggers[_userName].coinRaised, owed);
    msg.sender.transfer(owed);
    beggers[_userName].alive = false;
    beggers[_userName].completed = true;
  }

}
