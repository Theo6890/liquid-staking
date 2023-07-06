// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract sXYZ is ERC20, ReentrancyGuard {
    ISTakingXYZ public stakingXYZ;

    uint256 public total_staked_amount;
    uint256 public rewardsToClaim;

    mapping(address => uint256) public netTotalDelegated;
    mapping(address => uint256) public lastUnlockID;

    constructor(ISTakingXYZ stakingXYZ_) ERC20("Staked XYZ", "sXYZ") {
        stakingXYZ = stakingXYZ_;
    }

    // receive ETH from stakingXYZ
    fallback() external payable {
        // checks msg.data to ensure it comes from `stakingXYZ.withdrawUndelegated`
    }

    function claimRewards() public {
        total_staked_amount += stakingXYZ.claimRewards();
        rewardsToClaim += stakingXYZ.claimRewards();
    }

    /**
     * @notice Relayer fee is subtracted at deposit time as it pays the relayer
     *      to bridge delegate, undelegate and claimUndelegated calls from an
     *      EVM chain to a non-EVM chain.
     *
     *      If relayer fee is taken at a later stage (unlock or withdraw) it
     *      means that the relayer in in debt until the user unlock or withdraw,
     *      which in worst case scenario might never happens (wallet access
     *      lost, forgotten staking, stake forever as truly believes in the
     *      protocol....).
     */
    function deposit(address validator) public payable {
        require(
            msg.value > stakingXYZ.getRelayerFee(),
            "sXYZ: deposit <= relayerFee"
        );
        uint256 netDeposit = msg.value - stakingXYZ.getRelayerFee();

        total_staked_amount += netDeposit;
        netTotalDelegated[msg.sender] += netDeposit;

        _mint(msg.sender, netDeposit);

        stakingXYZ.delegate{value: msg.value}(validator, netDeposit);
    }

    function unlock(address validator, uint256 amount) public nonReentrant {
        uint256 delegated = netTotalDelegated[msg.sender];
        require(amount <= delegated, "sXYZ: amount > delegated");
        require(lastUnlockID[msg.sender] == 0, "sXYZ: pending undelegation");

        // rewardsToClaim -= unstaked;

        _burn(msg.sender, amount);

        lastUnlockID[msg.sender] = stakingXYZ.undelegate(validator, amount);
    }

    function withdraw(uint256 ID) public nonReentrant {
        uint256 unstaked = stakingXYZ.withdrawUndelegated(ID);

        total_staked_amount -= amount;
        // rewardsToClaim -= unstaked;
        netTotalDelegated[msg.sender] -= unstaked;
        lastUnlockID[msg.sender][msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: unstaked}(
            "sXYZ withdrawl"
        );
        require(sent, "Failed to send Ether");
    }

    function getRewardsOf(
        address delegator,
        uint255 unstaked
    ) public view returns (uint256) {
        uint256 portionUnstaked = (unstaked * 1 ether) /
            netTotalDelegated[delegator];
        uint256 portionOfTotalStaked = (netTotalDelegated[delegator] *
            1 ether) / total_staked_amount;

        return rewardsToClaim * portionUnstaked * portionOfTotalStaked;
    }
}
