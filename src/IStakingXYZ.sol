// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ISTakingXYZ {
    // address relayer;

    // mapping(uint256 => Receipt[]) public receipts;
    // mapping(address => bool) public registeredValidators;

    struct Receipt {
        uint256 amount;
        uint256 unstakedAt;
    }

    // delegate `amount` to `validator`
    /**
     * @dev - reverts if: `validator` not in `registeredValidators`
     *
     *      - sends `amount` to `validator` (from `msg.value`)
     *      - sends `getRelayerFee()` to `relayer` (from `msg.value`)
     */
    function delegate(address validator, uint256 amount) external payable;

    // undelegate `amount` from `validator`
    /**
     * @dev - reverts if: `validator` not in `registeredValidators`
     *
     *      - queue `amount` for undelegation from `validator`
     *      - saves undelegation data: Receipt(amount, block.timestamp) in `receipts[ID]`
     *
     *
     * @return undelegation identifier
     */
    function undelegate(
        address validator,
        uint256 amount
    ) external payable returns (uint256 ID);

    // claim undelegated amount once pending undelegate time has elapsed
    /**
     * @dev - reverts if: `block.timestamp < receipts[id].unstakedAt + getUndelegateTime()`
     *
     *      - sends `receipts[id].amount` to `msg.sender` (sXYZ)
     *
     *
     * @return undelegated amount
     */
    function withdrawUndelegated(
        uint256 id
    ) external payable returns (uint256 amount);

    // Claim pending rewards for msg.sender
    function claimReward() external returns (uint256 amount);

    // Get the total amount delegated by a delegator
    /**
     * @dev As only sXYZ is using this contract in this scope, it will return
     *      `IsXYZ(delegator).totalSupply()`.
     */
    function getTotalDelegated(
        address delegator
    ) external view returns (uint256);

    // Returns the undelegation time
    function getUndelegateTime() external view returns (uint256);

    // Returns the relayer fee
    function getRelayerFee() external view returns (uint256);
}
