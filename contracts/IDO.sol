//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "./IPool.sol";
import "./DeployPoolLibrary.sol";
import "./ConfigurePoolLibrary.sol";

contract IDO {
    address[] public poolAddresses;
    uint256[] public poolFixedFee;
    uint8 public poolPercentFee;
    uint8 public poolTokenPercentFee;
    mapping(address => address) public poolOwners;
    struct PoolModel {
        uint256 hardCap; // how much project wants to raise
        uint256 softCap; // how much of the raise will be accepted as successful IDO
        uint256 presaleRate;
        uint8 dexCapPercent;
        uint256 dexRate;
        uint8 tier;
    }

    struct PoolDetails {
        uint256 startDateTime;
        uint256 endDateTime;
        uint256 listDateTime;
        uint256 minAllocationPerUser;
        uint256 maxAllocationPerUser;
        uint16 dexLockup;
        bool whitelistable;
    }

    event LogPoolCreated(address poolOwner, address pool);
    event LogPoolKYCUpdate(address pool, bool kyc);
    event LogPoolAuditUpdate(address pool, bool audit, string auditLink);

    event LogPoolTierUpdate(address pool, uint8 tier);
    event LogPoolExtraData(address pool, string _extraData);
    event LogDeposit(address pool, address participant, uint256 amount);
    event LogPoolStatusChanged(address pool, uint256 status);
    event LogFeeChanged(
        uint256[] poolFixedFee,
        uint8 poolPercentFee,
        uint8 poolTokenPercentFee
    );
    event LogAddressWhitelisted(address pool, address[] whitelistedAddresses);
    event LogUpdateWhitelistable(address _pool, bool whitelistable);
    event MyLogNumber(uint256 myuint256);
    event MyLogAddress(string mystring, address myaddress);
    event MyLogString(string mystring);

    modifier _feeEnough(uint8 tier) {
        require((msg.value >= poolFixedFee[tier]), "Not enough fee!");
        _;
    }

    modifier _onlyPoolOwner(address _pool, address _owner) {
        require(poolOwners[_pool] == _owner, "Not Owner!");
        _;
    }
    modifier _onlyPoolOwnerAndOwner(address _pool, address _owner) {
        require(poolOwners[_pool] == _owner, "Not Owner!");
        _;
    }

    constructor() {
        uint256[] memory _poolFixedFee = new uint256[](4);
        _poolFixedFee[0] = 0;
        _poolFixedFee[1] = 0;
        _poolFixedFee[2] = 0;
        _poolFixedFee[3] = 0;

        uint8 _poolPercentFee = 0;
        uint8 _poolTokenPercentFee = 0;

        initialize(_poolFixedFee, _poolPercentFee, _poolTokenPercentFee);
    }

    function initialize(
        uint256[] memory _poolFixedFee,
        uint8 _poolPercentFee,
        uint8 _poolTokenPercentFee
    ) public {
        poolFixedFee = _poolFixedFee;
        poolPercentFee = _poolPercentFee;
        poolTokenPercentFee = _poolTokenPercentFee;
    }

    function createPool(
        PoolModel calldata model,
        PoolDetails calldata details,
        address _poolOwner,
        string memory _extraData
    ) external payable _feeEnough(model.tier) returns (address poolAddress) {
        uint256 poollength = poolAddresses.length;
        poolAddress = DeployPoolLibrary.deployPool(_poolOwner, poollength);
        emit MyLogAddress("poolAddress", poolAddress);

        ConfigurePoolLibrary.configurePool(
            poolAddress,
            IPool.PoolModel({
                hardCap: model.hardCap,
                softCap: model.softCap,
                presaleRate: model.presaleRate,
                dexCapPercent: model.dexCapPercent,
                dexRate: model.dexRate,
                projectTokenAddress: address(0),
                status: IPool.PoolStatus(0),
                tier: IPool.PoolTier(model.tier),
                kyc: false
            }),
            IPool.PoolDetails({
                startDateTime: details.startDateTime,
                endDateTime: details.endDateTime,
                listDateTime: details.listDateTime,
                minAllocationPerUser: details.minAllocationPerUser,
                maxAllocationPerUser: details.maxAllocationPerUser,
                dexLockup: details.dexLockup,
                extraData: _extraData,
                whitelistable: details.whitelistable,
                audit: false,
                auditLink: ""
            }),
            msg.sender, //admin
            _poolOwner, //pool owner
            poolPercentFee,
            poolTokenPercentFee
        );

        poolAddresses.push(poolAddress);
        poolOwners[poolAddress] = msg.sender;
        emit LogPoolCreated(msg.sender, poolAddress);
    }

    function setAdminFee(
        uint256[] memory _poolFixedFee,
        uint8 _poolPercentFee,
        uint8 _poolTokenPercentFee
    ) public {
        poolFixedFee = _poolFixedFee;
        poolPercentFee = _poolPercentFee;
        poolTokenPercentFee = _poolTokenPercentFee;
        emit LogFeeChanged(poolFixedFee, poolPercentFee, poolTokenPercentFee);
    }

    function updateExtraData(address _pool, string memory _extraData)
        external
        _onlyPoolOwner(_pool, msg.sender)
    {
        IPool(_pool).updateExtraData(_extraData);
        emit LogPoolExtraData(_pool, _extraData);
    }

    function updateKYCStatus(address _pool, bool _kyc) external {
        IPool(_pool).updateKYCStatus(_kyc);
        emit LogPoolKYCUpdate(_pool, _kyc);
    }

    function updateAuditStatus(
        address _pool,
        bool _audit,
        string memory _auditLink
    ) external {
        IPool(_pool).updateAuditStatus(_audit, _auditLink);
        emit LogPoolAuditUpdate(_pool, _audit, _auditLink);
    }

    function updateTierStatus(address _pool, uint8 _tier) external {
        IPool(_pool).updateTierStatus(IPool.PoolTier(_tier));
        emit LogPoolTierUpdate(_pool, _tier);
    }

    function addAddressesToWhitelist(
        address _pool,
        address[] calldata whitelistedAddresses
    ) external _onlyPoolOwner(_pool, msg.sender) {
        IPool(_pool).addAddressesToWhitelist(whitelistedAddresses);
        emit LogAddressWhitelisted(_pool, whitelistedAddresses);
    }

    function updateWhitelistable(address _pool, bool whitelistable)
        external
        _onlyPoolOwner(_pool, msg.sender)
    {
        IPool(_pool).updateWhitelistable(whitelistable);
        emit LogUpdateWhitelistable(_pool, whitelistable);
    }

    function setProjectToken(address _pool, address _projectTokenAddress) external {
        IPool(_pool).setProjectToken(_projectTokenAddress);      
    }

    function deposit(address _pool) external payable {
        IPool(_pool).deposit{value: msg.value}(msg.sender);
        emit LogDeposit(_pool, msg.sender, msg.value);
    }

    function cancelPool(address _pool)
        external
        _onlyPoolOwnerAndOwner(_pool, msg.sender)
    {
        IPool(_pool).cancelPool();
        emit LogPoolStatusChanged(_pool, uint256(IPool.PoolStatus.Cancelled));
    }

    function claimToken(address _pool) external {
        IPool(_pool).claimToken(msg.sender);
    }

    function refund(address _pool) external {
        IPool(_pool).refund(msg.sender);
        emit LogPoolStatusChanged(_pool, uint256(IPool.PoolStatus.Cancelled));
    }

    function endPool(address _pool) external _onlyPoolOwner(_pool, msg.sender) {
        IPool(_pool).endPool();
        emit LogPoolStatusChanged(_pool, uint256(IPool.PoolStatus.Listed));
    }

    function unlockLiquidityDex(address _pool) external {
        IPool(_pool).unlockLiquidityDex();
        emit LogPoolStatusChanged(_pool, uint256(IPool.PoolStatus.Unlocked));
    }
}
