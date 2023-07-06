// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISTakingXYZ {
    // address relayer;
    // IsXYZ public sXYZ;

    struct Receipt {
        uint256 amount;
        uint256 unstakedAt;
    }

    // delegate `amount` to `validator`
    /**
     * @dev - checks `validator` is registered in StakingXYZ, otherwise reverts
     *      - sends `amount` to `validator`
     *      - sends `getRelayerFee()` to `relayer`
     */
    function delegate(address validator, uint256 amount) external payable;

    // undelegate `amount` from `validator`
    /**
     * @dev - checks `validator` is registered in StakingXYZ, otherwise reverts
     *      - queue `amount` undelegation from `validator`
     */
    function undelegate(
        address validator,
        uint256 amount
    ) external payable returns (uint256 ID);

    // claim undelegated amount once pending undelegate time has elapsed
    /**
     * @dev reverts if: `block.timestamp < ids[id].unstakedAt + getUndelegateTime()`
     * @return undelegated amount
     */
    function withdrawUndelegated(
        uint256 id
    ) external payable returns (uint256 amount);

    // Claim pending rewards for msg.sender
    function claimReward() external returns (uint256 amount);

    // Get the total amount delegated by a delegator
    ///@return `sXYZ.netTotalDelegated(delegator)`
    function getTotalDelegated(
        address delegator
    ) external view returns (uint256);

    // Returns the undelegation time
    function getUndelegateTime() external view returns (uint256);

    // Returns the relayer fee
    function getRelayerFee() external view returns (uint256);
}
