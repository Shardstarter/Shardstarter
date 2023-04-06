//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


import "./Pool.sol";
library DeployPoolLibrary {

  function deployPool(
    address projectTokenAddress,
    uint256 nonce
  )
    public 
    returns (address poolAddress)
  {
    bytes memory bytecode = type(Pool).creationCode;
    bytes32 salt = keccak256(abi.encodePacked(msg.sender, projectTokenAddress, nonce));
    assembly {
        poolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }
    
    return poolAddress;
  }
  

 
}
