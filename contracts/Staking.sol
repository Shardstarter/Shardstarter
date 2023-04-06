// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
  IERC20 public rewardsToken;
  IERC20 public stakingToken;

  uint public rewardRate;
  uint public lastUpdateTime;
  uint public rewardPerTokenStored;

  mapping(address => uint) public userRewardPerTokenPaid;
  mapping(address => uint) public rewards;
  mapping(address => uint256) public lockingReleaseTime; //end time of users' locking
  uint256 public locktime = 56 days; //lock time is 8 weeks
  uint256 public unstakefee = 25; //25% for before lock time, will be 0 by lockingreleasetime
  address private mainWallet = 0x791320012C079fDF833244C65c343cbAB34C6ab6;

  uint public _totalSupply;
  mapping(address => uint) public balances;

  constructor(address _stakingToken, address _rewardsToken, uint256 _rewardRate) {
    stakingToken = IERC20(_stakingToken);
    rewardsToken = IERC20(_rewardsToken);
    rewardRate = _rewardRate;
  }

  function rewardPerToken() public view returns (uint) {
    if (_totalSupply == 0) {
      return rewardPerTokenStored;
    }
    return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / _totalSupply);
  }

  function earned(address account) public view returns (uint) {
    return ((balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = block.timestamp;

    rewards[account] = earned(account);
    userRewardPerTokenPaid[account] = rewardPerTokenStored;
    _;
  }

  function stake(uint _amount) external updateReward(msg.sender) {
    _totalSupply += _amount;
    balances[msg.sender] += _amount;
    stakingToken.transferFrom(msg.sender, address(this), _amount);
    lockingReleaseTime[msg.sender] = block.timestamp + locktime;
  }

  function withdraw(uint256 _amount) external updateReward(msg.sender) {
    _totalSupply -= _amount;
    balances[msg.sender] -= _amount;

    uint256 fee;
    uint256 sending_amount;
    if (block.timestamp > lockingReleaseTime[msg.sender]) sending_amount = _amount;
    else {
      fee = (_amount * unstakefee * (lockingReleaseTime[msg.sender] - block.timestamp)) / locktime / 100;
      sending_amount = _amount - fee;
    }
    if (fee > 0) stakingToken.transfer(mainWallet, fee);
    stakingToken.transfer(msg.sender, sending_amount);
  }

  function getReward() external updateReward(msg.sender) {
    uint reward = rewards[msg.sender];
    rewards[msg.sender] = 0;
    rewardsToken.transfer(msg.sender, reward);
    lockingReleaseTime[msg.sender] = block.timestamp + locktime;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint);

  function balanceOf(address account) external view returns (uint);

  function transfer(address recipient, uint amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint);

  function approve(address spender, uint amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
