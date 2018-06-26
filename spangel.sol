pragma solidity ^0.4.20;

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
    bool alive;
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

  constructor() public {
    bank = 0;
    creator = msg.sender;
    beggerCount = 0;
  }

  function createBegger(bytes32 _userName, uint _projected) public isNew(_userName) {
    beggers[_userName].completed = false;
    beggers[_userName].coinRaised = 0;
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
    beggers[_userName].coinRaised = beggers[_userName].coinRaised + msg.value;
    if (beggers[_userName].coinRaised >= beggers[_userName].projected) {
      beggers[_userName].resolver.transfer(beggers[_userName].projected - (beggers[_userName].projected / 100));
      msg.sender.transfer(beggers[_userName].coinRaised - beggers[_userName].projected);
      bank = bank - beggers[_userName].projected - (beggers[_userName].projected / 100);
      bank = bank - beggers[_userName].coinRaised - beggers[_userName].projected;
      beggers[_userName].alive = false;
      beggers[_userName].completed = true;
    }
    bank = bank + msg.value;
  }

  function giveUp(bytes32 _userName) public isOwner(_userName) isAlive(_userName) {
    beggers[_userName].resolver.transfer(beggers[_userName].coinRaised - (beggers[_userName].coinRaised / 20));
    bank = bank - beggers[_userName].coinRaised - (beggers[_userName].coinRaised / 20);
    beggers[_userName].alive = false;
    beggers[_userName].completed = true;
  }

}
