//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./IPool.sol";
library PoolLibrary {
  using SafeMath for uint256;
  function _preValidatePoolDetails(IPool.PoolDetails memory _poolDetails) public view {  
    require(
      _poolDetails.startDateTime >= block.timestamp,"startDate fail!"
    );

    require(
      _poolDetails.listDateTime >= _poolDetails.endDateTime,"end<=list!"
    ); 
    require(
      _poolDetails.startDateTime < _poolDetails.endDateTime,"start<end!"
    );
    require(
      _poolDetails.dexLockup >= 30,"lockup>=30!"
    ); 
    require(_poolDetails.minAllocationPerUser > 0);
    require(
      _poolDetails.minAllocationPerUser <= _poolDetails.maxAllocationPerUser,"min<max"
    );
  
  }
  function _preValidatePoolCreation(IPool.PoolModel memory _pool, address _poolOwner, uint8 _poolPercentFee) public pure {
    require(_pool.hardCap > 0, "hardCap > 0");
    require(_pool.softCap > 0, "softCap > 0");
    require(_pool.softCap < _pool.hardCap, "softCap < hardCap");
    require(
      address(_poolOwner) != address(0),
      "Owner is a zero address!"
    );
    require(_pool.dexCapPercent >= 51 && _pool.dexCapPercent < 100, "dexCapPercent is 51~99%");
    require(_pool.dexRate > 0, "dexRate > 0!");
    require(_pool.presaleRate > 0, "presaleRate > 0!");
    require(_poolPercentFee >= 0 && _poolPercentFee<100, "percentFee!");
  }

  function _poolIsOngoing(IPool.PoolStatus status,IPool.PoolDetails memory _poolDetails) public view {  
    require(status==IPool.PoolStatus.Inprogress, "not available!"); 
    // solhint-disable-next-line not-rely-on-time
    require(_poolDetails.startDateTime <= block.timestamp, "not started!");
    // solhint-disable-next-line not-rely-on-time
    require(_poolDetails.endDateTime >= block.timestamp, "ended!");
  }

  function _poolIsUpcoming(IPool.PoolStatus status,IPool.PoolDetails memory _poolDetails) public view {  
    require(status==IPool.PoolStatus.Inprogress, "not available!"); 
    // solhint-disable-next-line not-rely-on-time
    require(_poolDetails.startDateTime > block.timestamp, "started!");   
  }




  function _poolIsNotCancelled(IPool.PoolModel memory _pool) public pure {
    require(
      _pool.status!= IPool.PoolStatus.Cancelled && _pool.status!= IPool.PoolStatus.Listed,
      "already cancelled!"
    );
  }

  function _poolIsCancelled(IPool.PoolModel memory _pool, IPool.PoolDetails memory _poolDetails, uint256 _weiRaised) public view {
    require(
      _pool.status== IPool.PoolStatus.Cancelled || 
      (_pool.status== IPool.PoolStatus.Inprogress && _poolDetails.listDateTime+21 days<= block.timestamp) || 
      (_pool.status== IPool.PoolStatus.Inprogress && 
      _poolDetails.endDateTime<= block.timestamp && _pool.softCap>_weiRaised),
      "not cancelled!"
    );
  }

  function _poolIsEnd(IPool.PoolModel memory _pool, IPool.PoolDetails memory _poolDetails, uint256 _weiRaised) public view {
    require(
      _poolDetails.endDateTime <= block.timestamp && _pool.status== IPool.PoolStatus.Inprogress && _pool.softCap<=_weiRaised,
      "not finalized!"
    );
  }

  function _poolIsListed(IPool.PoolModel memory _pool) public pure {
    require(
      _pool.status== IPool.PoolStatus.Listed, "not finalized!"
    );
  }

  function _poolIsReadyUnlock(IPool.PoolModel memory _pool, IPool.PoolDetails memory _poolDetails) public view {
    require(
      _poolDetails.listDateTime+_poolDetails.dexLockup*1 days<= block.timestamp && _pool.status== IPool.PoolStatus.Listed,
      "lockup!"
    );
  }

  function _hardCapNotPassed(uint256 _hardCap, uint256 _weiRaised) public view  {
    uint256 _beforeBalance = _weiRaised;
    uint256 sum = _weiRaised + msg.value;
    require(sum <= _hardCap, "hardCap!");
    require(sum > _beforeBalance, "hardCap overflow!");
  }

  function _minAllocationNotPassed(uint256 _minAllocationPerUser, uint256 _weiRaised, uint256 hardCap) public view  {
    require(hardCap.sub(_weiRaised)<_minAllocationPerUser || _minAllocationPerUser <= msg.value, "Less!");
  }

  function _maxAllocationNotPassed(uint256 _maxAllocationPerUser, uint256 collaboration) public view  {
    uint256 aa=collaboration + msg.value;

    require(aa <= _maxAllocationPerUser, "More!");
  }

}