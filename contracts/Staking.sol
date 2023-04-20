// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingRewards is Ownable {
    IERC20 public rewardsToken;
    IERC20 public stakingToken;

    uint public rewardRate;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;

    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint256) public lockingReleaseTime; //end time of users' locking
    uint256 public locktime; //lock time
    uint256 public unstakefee = 25; //25% for before lock time, will be 0 by lockingreleasetime
    address public mainWallet;

    uint public _totalSupply;
    mapping(address => uint) public balances;

    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor(
        address _stakingToken,
        address _rewardsToken,
        uint256 _rewardRate,
        uint256 _lockingdays,
        address _mainWallet
    ) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        rewardRate = _rewardRate;
        locktime = _lockingdays * 1 days;
        mainWallet = _mainWallet;
    }

    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) /
                _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) +
            rewards[account];
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }

    function stake(uint _amount) external updateReward(msg.sender) noReentrant {
        require(_amount > 0, "No amount to stake");
        require(
            _amount <= IERC20(stakingToken).balanceOf(msg.sender),
            "Insufficient balance"
        );
        stakingToken.transferFrom(msg.sender, address(this), _amount);

        _totalSupply += _amount;
        balances[msg.sender] += _amount;
        lockingReleaseTime[msg.sender] = block.timestamp + locktime;
    }

    function withdraw(
        uint256 _amount
    ) external updateReward(msg.sender) noReentrant {
        require(_amount > 0, "No amount to withdraw");
        require(
            IERC20(stakingToken).balanceOf(address(this)) >= _amount,
            "Insufficient balance"
        );

        _totalSupply -= _amount;
        balances[msg.sender] -= _amount;

        uint256 fee;
        uint256 sending_amount;
        if (block.timestamp > lockingReleaseTime[msg.sender])
            sending_amount = _amount;
        else {
            fee =
                (_amount *
                    unstakefee *
                    (lockingReleaseTime[msg.sender] - block.timestamp)) /
                locktime /
                100;
            sending_amount = _amount - fee;
        }
        if (fee > 0) stakingToken.transfer(mainWallet, fee);
        stakingToken.transfer(msg.sender, sending_amount);
    }

    function getReward() external updateReward(msg.sender) noReentrant {
        uint reward = rewards[msg.sender];
        require(reward > 0, "No reward to withdraw");
        require(
            IERC20(stakingToken).balanceOf(address(this)) >= reward,
            "Insufficient balance"
        );
        rewardsToken.transfer(msg.sender, reward);

        rewards[msg.sender] = 0;
        lockingReleaseTime[msg.sender] = block.timestamp + locktime;
    }

    // admin functions
    function setMainWallet(address _mainWallet) external onlyOwner {
        mainWallet = _mainWallet;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
