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

  modifier isAlive(bytes32 _uuid) {
    require(beggers[_uuid].alive == true);
    _;
  }

  modifier isOwner(bytes32 _uuid) {
    require(beggers[_uuid].owner == msg.sender);
    _;
  }

  modifier isExpired(bytes32 _uuid) {
    require(beggers[_uuid].ttl >= now);
    _;
  }

  modifier isGiver(bytes32 _uuid) {
    require(beggers[_uuid].givers[msg.sender] > 0);
    _;
  }

  constructor() public {
    bank = 0;
    creator = msg.sender;
    beggerCount = 0;
  }

  function createBegger(bytes32 _uuid, uint ttl, uint _projected) public {
    require(beggers[_uuid].owner == address(0x0));
    beggers[_uuid].completed = false;
    beggers[_uuid].coinRaised = 0;
    ttl = SafeMath.mul(ttl, 1 days);
    beggers[_uuid].ttl = SafeMath.add(ttl, now);
    beggers[_uuid].projected = _projected;
    beggers[_uuid].alive = true;
    beggers[_uuid].owner = msg.sender;
    beggerCount++;
  }

  function addResolver(bytes32 _uuid, address _resolver) public isOwner(_uuid) isAlive(_uuid) {
    beggers[_uuid].resolver = _resolver;
  }

  function give(bytes32 _uuid) public payable isAlive(_uuid) {
    require(msg.value < beggers[_uuid].projected);
    beggers[_uuid].coinRaised = SafeMath.add(beggers[_uuid].coinRaised, SafeMath.div(msg.value, 200));
    bank = SafeMath.add(bank, msg.value);
    beggers[_uuid].givers[msg.sender] = SafeMath.add(msg.value, beggers[_uuid].givers[msg.sender]);

    if (beggers[_uuid].coinRaised >= beggers[_uuid].projected) {
      beggers[_uuid].resolver.transfer(beggers[_uuid].projected);
      msg.sender.transfer(SafeMath.sub(beggers[_uuid].coinRaised, beggers[_uuid].projected));
      bank = SafeMath.sub(bank, beggers[_uuid].projected);
      bank = SafeMath.sub(bank, SafeMath.sub(beggers[_uuid].coinRaised, beggers[_uuid].projected));
      beggers[_uuid].alive = false;
      beggers[_uuid].completed = true;
    }

  }

  function refund(bytes32 _uuid) public isGiver(_uuid) isExpired(_uuid) {
    uint owed;
    owed = beggers[_uuid].givers[msg.sender];
    beggers[_uuid].givers[msg.sender] = 0;
    bank = SafeMath.sub(bank, owed);
    beggers[_uuid].coinRaised = SafeMath.sub(beggers[_uuid].coinRaised, owed);
    msg.sender.transfer(owed);
    beggers[_uuid].alive = false;
    beggers[_uuid].completed = true;
  }

}
