
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IPool.sol";

library ConfigurePoolLibrary {
    using SafeMath for uint256;
    using SafeMath for uint8;

    event MyLogNumber(string information, uint256 myuint256);

    function configurePool(
        address poolAddress,
        IPool.PoolModel calldata _pool,
        IPool.PoolDetails calldata _details,
        address _admin,
        address _poolOwner,
        uint8 _poolPercentFee,
        uint8 _poolTokenPercentFee
    ) public {
        IPool(poolAddress).setPoolModel(
            _pool,
            _details,
            _admin,
            _poolOwner,
            _poolPercentFee
        );
        return; // no need to transfer token to IDO
        
        IERC20Metadata projectToken = IERC20Metadata(_pool.projectTokenAddress);
        uint256 totalTokenAmount = _pool.hardCap.mul(_pool.presaleRate).add(
            _pool.hardCap.mul(_pool.dexRate.mul(_pool.dexCapPercent)) / 100
        );

        totalTokenAmount = totalTokenAmount.div(10**18);
        totalTokenAmount = totalTokenAmount.add(
            totalTokenAmount.mul(_poolTokenPercentFee) / 100
        );
        emit MyLogNumber("totalTokenAmount", totalTokenAmount);

        require(
            totalTokenAmount <= projectToken.balanceOf(msg.sender),
            "insufficient funds for transfer"
        );

        projectToken.transferFrom(msg.sender, poolAddress, totalTokenAmount);
        uint256 restToken = totalTokenAmount.sub(
            projectToken.balanceOf(poolAddress)
        );
        if (restToken > 0) {
            restToken = restToken.mul(totalTokenAmount).div(
                projectToken.balanceOf(poolAddress)
            );
            require(
                restToken <= projectToken.balanceOf(msg.sender),
                "insufficient funds for transfer"
            );
            projectToken.transferFrom(msg.sender, poolAddress, restToken);
        }
    }
}
