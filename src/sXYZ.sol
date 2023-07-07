// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import {IStakingXYZ} from "./IStakingXYZ.sol";

contract sXYZ is ERC20, ReentrancyGuard {
    IStakingXYZ public stakingXYZ;
    address public validator;

    uint256 public total_staked_amount;
    uint256 public rewardsToClaim;

    mapping(address => uint256) public lastUnlockID;

    constructor(
        IStakingXYZ stakingXYZ_,
        address validator_
    ) ERC20("Staked XYZ", "sXYZ") {
        stakingXYZ = stakingXYZ_;
        validator = validator_;
    }

    // TODO: receive ETH from stakingXYZ
    fallback() external payable {
        // checks msg.data to ensure it comes from `stakingXYZ.withdrawUndelegated`
    }

    function claimRewards() public {
        total_staked_amount += stakingXYZ.claimReward();
        rewardsToClaim += stakingXYZ.claimReward();
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
    function deposit() public payable {
        require(
            msg.value > stakingXYZ.getRelayerFee(),
            "sXYZ: deposit <= relayerFee"
        );
        uint256 netDeposit = msg.value - stakingXYZ.getRelayerFee();

        total_staked_amount += netDeposit;

        _mint(msg.sender, netDeposit);

        stakingXYZ.delegate{value: msg.value}(validator, netDeposit);
    }

    function unlock(uint256 amount) public nonReentrant {
        require(lastUnlockID[msg.sender] == 0, "sXYZ: pending undelegation");

        // require(accountBalance >= amount...) allows to check `amount` is not
        // greater to net delegated amount
        _burn(msg.sender, amount);

        lastUnlockID[msg.sender] = stakingXYZ.undelegate(validator, amount);
    }

    function withdraw(uint256 ID) public nonReentrant {
        uint256 unstaked = stakingXYZ.withdrawUndelegated(ID);
        uint256 earned = getRewardsOf(msg.sender, unstaked);

        // update total staked here as undelegate can potentially fail even if
        // unlock does not fail
        total_staked_amount -= unstaked;
        rewardsToClaim -= earned;

        lastUnlockID[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: unstaked + earned}(
            "sXYZ withdrawl"
        );
        require(sent, "Failed to send Ether");
    }

    function getRewardsOf(
        address delegator,
        uint256 unstaked
    ) public view returns (uint256) {
        uint256 portionUnstaked = (unstaked * 1 ether) / balanceOf(delegator);
        uint256 portionOfTotalStaked = (balanceOf(delegator) * 1 ether) /
            total_staked_amount;

        return rewardsToClaim * portionUnstaked * portionOfTotalStaked;
    }
}
