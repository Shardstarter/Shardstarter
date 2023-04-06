//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IPool.sol";
import "./Whitelist.sol";
import "./IPancakeRouter02.sol";
import "./IPancakeFactory.sol";
import "./IPancakePair.sol";
import "./PoolLibrary.sol";

contract Pool is IPool, Whitelist {
    using SafeMath for uint256;
    using SafeMath for uint8;
    IERC20Metadata private projectToken;
    PoolModel public poolInformation;
    PoolDetails public poolDetails;
    address public poolOwner;
    address public admin;
    address public factory;
    address[] public participantsAddress;
    mapping(address => uint256) public collaborations;
    uint256 public _weiRaised = 0;
    mapping(address => bool) public _didRefund;
    uint8 public poolPercentFee;

    constructor() {
        factory = msg.sender;
    }

    event MyLogAddress(string log, address myaddress);

    function setPoolModel(
        PoolModel calldata _pool,
        IPool.PoolDetails calldata _details,
        address _admin,
        address _poolOwner,
        uint8 _poolPercentFee
    ) external override _onlyFactory {
        PoolLibrary._preValidatePoolCreation(
            _pool,
            _poolOwner,
            _poolPercentFee
        );
        poolInformation = _pool;
        PoolLibrary._preValidatePoolDetails(_details);
        poolDetails = _details;
        poolOwner = _poolOwner;
        admin = _admin;
        poolPercentFee = _poolPercentFee;
    }

    function setProjectToken(address _projectTokenAddress) external _onlyFactory {
        poolInformation.projectTokenAddress = _projectTokenAddress;
    }

    modifier _onlyFactory() {
        require(factory == msg.sender, "Not factory!");
        _;
    }

    modifier _onlyAdmin() {
        require(admin == msg.sender, "Not Admin!");
        _;
    }

    function updateExtraData(string memory _extraData)
        external
        override
        _onlyFactory
    {
        PoolLibrary._poolIsNotCancelled(poolInformation);
        poolDetails.extraData = _extraData;
    }

    function updateKYCStatus(bool _kyc) external override _onlyFactory {
        poolInformation.kyc = _kyc;
    }

    function updateAuditStatus(bool _audit, string memory _auditLink)
        external
        override
        _onlyFactory
    {
        poolDetails.audit = _audit;
        poolDetails.auditLink = _auditLink;
    }

    function updateTierStatus(PoolTier _tier) external override _onlyFactory {
        poolInformation.tier = _tier;
    }

    function updateWhitelistable(bool _whitelistable)
        external
        override
        _onlyFactory
    {
        PoolLibrary._poolIsUpcoming(poolInformation.status, poolDetails);
        poolDetails.whitelistable = _whitelistable;
    }

    function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
        external
        override
        _onlyFactory
    {
        PoolLibrary._poolIsNotCancelled(poolInformation);
        addToWhitelist(whitelistedAddresses);
    }

    function deposit(address sender) external payable override _onlyFactory {
        PoolLibrary._poolIsOngoing(poolInformation.status, poolDetails);
        _onlyWhitelisted(sender);
        PoolLibrary._minAllocationNotPassed(
            poolDetails.minAllocationPerUser,
            _weiRaised,
            poolInformation.hardCap
        );
        PoolLibrary._maxAllocationNotPassed(
            poolDetails.maxAllocationPerUser,
            collaborations[sender]
        );
        PoolLibrary._hardCapNotPassed(poolInformation.hardCap, _weiRaised);

        uint256 _amount = msg.value;
        _increaseRaisedWEI(_amount);
        _addToParticipants(sender);
    }

    function cancelPool() external override _onlyFactory {
        PoolLibrary._poolIsNotCancelled(poolInformation);
        projectToken = IERC20Metadata(poolInformation.projectTokenAddress);
        poolInformation.status = PoolStatus.Cancelled;
        // if (projectToken.balanceOf(address(this)) > 0)
        //     projectToken.transfer(
        //         address(poolOwner),
        //         projectToken.balanceOf(address(this))
        //     );
    }

    function refund(address claimer) external override _onlyFactory {
        PoolLibrary._poolIsCancelled(poolInformation, poolDetails, _weiRaised);
        if (_didRefund[claimer] != true && collaborations[claimer] > 0) {
            _didRefund[claimer] = true;
            payable(claimer).transfer(collaborations[claimer]);
        }
        if (poolInformation.softCap <= _weiRaised)
            poolInformation.status = PoolStatus.Cancelled;
    }

    function claimToken(address claimer) external override _onlyFactory {
        PoolLibrary._poolIsListed(poolInformation);
        projectToken = IERC20Metadata(poolInformation.projectTokenAddress);
        uint256 _amount = collaborations[claimer]
            .mul(poolInformation.presaleRate)
            .div(10**18);
        if (_didRefund[claimer] != true && _amount > 0) {
            _didRefund[claimer] = true;
            projectToken.transfer(claimer, _amount);
        }
    }

    function endPool() external override _onlyFactory {
        PoolLibrary._poolIsEnd(poolInformation, poolDetails, _weiRaised);
        projectToken = IERC20Metadata(poolInformation.projectTokenAddress);

        //pay for the project owner
        uint256 toAdminETHAmount = _weiRaised.mul(poolPercentFee).div(100);
        if (toAdminETHAmount > 0) payable(admin).transfer(toAdminETHAmount);
        uint256 rest = _weiRaised.sub(toAdminETHAmount);
        payable(poolOwner).transfer(rest);

        return;

        // Handling Dex listing

        // send ETH and Token back to the pool owner
        uint256 dexETHAmount = poolInformation
            .hardCap
            .mul(poolInformation.dexCapPercent)
            .div(100);
        if (dexETHAmount >= rest) {
            dexETHAmount = rest;
        } else {
            uint256 _toPoolOwner = rest.sub(dexETHAmount);
            if (_toPoolOwner > 0) payable(poolOwner).transfer(_toPoolOwner);
        }
        uint256 dexTokenAmount = dexETHAmount.mul(poolInformation.dexRate).div(
            10**18
        );
        //pay to the admin owner
        uint256 tokenToAdmin = projectToken
            .balanceOf(address(this))
            .sub(dexTokenAmount)
            .sub(
                poolInformation.hardCap.mul(poolInformation.presaleRate).div(
                    10**18
                )
            );
        if (tokenToAdmin > 0) {
            projectToken.transfer(address(admin), tokenToAdmin);
            require(
                tokenToAdmin <= projectToken.balanceOf(address(admin)),
                "remove tax"
            );
        }
        uint256 tokenRest = projectToken
            .balanceOf(address(this))
            .sub(dexTokenAmount)
            .sub(_weiRaised.mul(poolInformation.presaleRate).div(10**18))
            .sub(tokenToAdmin);
        if (tokenRest > 0) projectToken.transfer(address(poolOwner), tokenRest);
        poolInformation.status = PoolStatus.Listed;

        IPancakeFactory pancakeFactory = IPancakeFactory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        address LPAddress = pancakeFactory.getPair(
            poolInformation.projectTokenAddress,
            address(0xd0A1E359811322d97991E03f863a0C30C2cF029C)
        );
        require(LPAddress != address(0x0), "already existed!");
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(
            address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
        );
        pancakeRouter.addLiquidityETH{value: dexETHAmount}(
            poolInformation.projectTokenAddress,
            dexTokenAmount,
            0,
            0,
            address(this),
            block.timestamp + 360
        );
    }

    function unlockLiquidityDex() external override _onlyFactory {
        PoolLibrary._poolIsReadyUnlock(poolInformation, poolDetails);
        IPancakeFactory pancakeFactory = IPancakeFactory(
            address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f)
        );
        address LPAddress = pancakeFactory.getPair(
            poolInformation.projectTokenAddress,
            address(0xd0A1E359811322d97991E03f863a0C30C2cF029C)
        );
        IPancakePair pancakePair = IPancakePair(LPAddress);
        uint256 LPBalance = pancakePair.balanceOf(address(this));
        if (LPBalance > 0) pancakePair.transfer(poolOwner, LPBalance);
        poolInformation.status = IPool.PoolStatus.Unlocked;
    }

    function status() external view override returns (IPool.PoolStatus) {
        return poolInformation.status;
    }

    function endDateTime() external view override returns (uint256) {
        return poolDetails.endDateTime;
    }

    function listDateTime() external view override returns (uint256) {
        return poolDetails.listDateTime;
    }

    function startDateTime() external view override returns (uint256) {
        return poolDetails.startDateTime;
    }

    function _increaseRaisedWEI(uint256 _amount) private {
        require(_amount > 0, "No WEI found!");

        _weiRaised = _weiRaised.add(_amount);
    }

    function _addToParticipants(address _address) private {
        if (!_didAlreadyParticipated(_address))
            _addToListOfParticipants(_address);
        _keepRecordOfWEIRaised(_address);
    }

    function _didAlreadyParticipated(address _address)
        public
        view
        returns (bool isIt)
    {
        isIt = collaborations[_address] > 0;
    }

    function _addToListOfParticipants(address _address) private {
        participantsAddress.push(_address);
    }

    function _keepRecordOfWEIRaised(address _address) private {
        collaborations[_address] += msg.value;
    }

    function _onlyWhitelisted(address sender) public view {
        require(
            !poolDetails.whitelistable ||
                block.timestamp >= poolDetails.startDateTime + 10 minutes ||
                isWhitelisted(sender),
            "Not!"
        );
    }
}
