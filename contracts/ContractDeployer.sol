// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.1;

contract ContractDeployer {
  address public owner;
  uint public last_completed_migration;

  constructor() {
    owner = msg.sender;
  }

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    ContractDeployer upgraded = ContractDeployer(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}