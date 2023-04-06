//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ILock {
  event LockAdded(address _token, uint256 _endDateTime, uint256 _amount, address _owner, bool _isLiquidity, address creator, uint256 _startDateTime);
  event UnlockLiquidity(address _token, uint256 _endDateTime, uint256 _amount, address _owner);
  event UnlockToken(address _token, uint256 _endDateTime, uint256 _amount, address _owner);

  struct TokenList {
    uint256 amount;
    uint256 startDateTime;
    uint256 endDateTime;
    address owner;
    address creator;
  }
  function liquidities(uint) external view returns (address);
  function tokens(uint) external view returns (address);
  function add(address _token, uint256 _endDateTime, uint256 _amount, address _owner, bool _isLiquidity) external;
  function unlockLiquidity(address _token) external returns (bool);
  function unlockToken(address _token) external returns (bool);
}
