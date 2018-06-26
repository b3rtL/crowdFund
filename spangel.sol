pragma solidity ^0.4.20;

import "./SafeMath.sol";

contract Spangel {
  uint public bank;
  address creator;
  uint  public beggerCount;

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

  event CreatedBegger(bytes32 indexed _uuid);
  event Refunded(bytes32 _uuid, address indexed _giver, uint indexed _refund);
  event Give(bytes32 _uuid, uint indexed _given);
  event Completed(bytes32 indexed _uuid);


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
    beggers[_uuid].projected = SafeMath.mul(_projected, 1000000000000000000);
    beggers[_uuid].alive = true;
    beggers[_uuid].owner = msg.sender;
    beggerCount++;

    emit CreatedBegger(_uuid);
  }

  function addResolver(bytes32 _uuid, address _resolver) public isOwner(_uuid) isAlive(_uuid) {
    beggers[_uuid].resolver = _resolver;
  }

  function give(bytes32 _uuid) public payable isAlive(_uuid) {
    require(msg.value < beggers[_uuid].projected);
    uint fee = SafeMath.div(msg.value, 200);
    uint total = SafeMath.sub(msg.value, fee);
    beggers[_uuid].coinRaised += total;
    bank = address(this).balance;
    beggers[_uuid].givers[msg.sender] += SafeMath.sub(msg.value, fee);

    emit Give(_uuid, total);

    if (beggers[_uuid].coinRaised >= beggers[_uuid].projected) {
      beggers[_uuid].resolver.transfer(beggers[_uuid].projected);
      msg.sender.transfer(SafeMath.sub(beggers[_uuid].coinRaised, beggers[_uuid].projected));
      bank = SafeMath.sub(bank, beggers[_uuid].projected);
      bank = SafeMath.sub(bank, SafeMath.sub(beggers[_uuid].coinRaised, beggers[_uuid].projected));
      beggers[_uuid].alive = false;
      beggers[_uuid].completed = true;

      emit Completed(_uuid);
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

    emit Refunded(_uuid, msg.sender, owed);
  }
}
