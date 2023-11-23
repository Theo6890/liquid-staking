# Assignment

Create a simple liquid staking contract for a fictive native token XYZ (cfr. ETH on mainnet, not ERC20) that can be staked in StakingXYZ.

The liquid staking contract has to implement the ERC20 interface and contain the required functions to deposit, unlock and withdraw tokens. Whether you choose an aToken (rebasing) or cToken model is up to you.

The key assignment is implementing the correct logic for deposit and the unlock+withdraw workflow and taking the relayer fee into account correctly.

You should implement at least the following functions:

deposit (user deposits XYZ, gets sXYZ)
unlock (user burns sXYZ, gets a receipt for withdrawing a similar amount of XYZ after a waiting period , cfr withdrawal queue for ETH)
withdraw (redeem the receipt from unlock, get XYZ back)
Additionally you should write a basic unit test using Foundry for either deposit, unlock or withdraw (they get more complex in this order).

You can can assume claimRewards() in your contract is implemented as below, and called regularly by a third-party relayer on a daily basis to increase the total amount staked by your contract in StakingXYZ

```solidity
contract sXYZ is IERC20 {

...

    function claimRewards() public {
        // total_staked_amount += stakingXYZ.claimRewards();
    }

...

}
```

## Staking XYZ

### Undelegating (!!)

Undelegating creates a Receipt which holds the amount unstaked and the block height at which it was unstaked. undelegate will return the ID of this receipt, which can be redeemed once its undelegation time has elapsed.

```
struct Receipt {
    uint256 amount
    uint256 unstakedAt
}
```

### Relayer Fee

You will have to take into account that the user must pay a relayer fee to bridge delegate, undelegate and claimUndelegated calls from an EVM chain to a non-EVM chain. This relayer fee is paid in XYZ.

### Slashing

For reducing the scope of the assignment, you can assume there is no slashing

### Validator Set

For reducing the scope of the assignment, you can assume assets are always staked to the same validator

### Interface

The StakingXYZ contract has the following interface:

```
interface ISTakingXYZ {
    // delegate `amount` to `validator`
    function delegate(address validator, uint256 amount) external payable;
    // undelegate `amount` from `validator`
    function undelegate(address validator, uint256 amount) external payable returns (uint256 ID);
    // claim undelegated amount once pending undelegate time has elapsed
    function withdrawUndelegated(uint256 id) external payable returns (uint256 amount);
    // Claim pending rewards for msg.sender
    function claimReward() external returns (uint256 amount);

    // Get the total amount delegated by a delegator
    function getTotalDelegated(address delegator) external view returns (uint256);

    // Returns the undelegation time
    function getUndelegateTime() external view returns (uint256);

    // Returns the relayer fee
    function getRelayerFee() external view returns (uint256);
}
```
