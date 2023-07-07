// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

import {IStakingXYZ} from "./IStakingXYZ.sol";

contract sXYZ is ERC20, ReentrancyGuard {
    IStakingXYZ public stakingXYZ;
    address public validator;

    uint256 public total_staked_amount;

    mapping(address => uint256) public lastUnlockID;

    constructor(
        IStakingXYZ stakingXYZ_,
        address validator_
    ) ERC20("Staked XYZ", "sXYZ") {
        stakingXYZ = stakingXYZ_;
        validator = validator_;
    }

    fallback() external payable {
        // checks msg.data to ensure it comes from `stakingXYZ.claimReward()`
        // or `stakingXYZ.withdrawUndelegated(...)` otherwise reverts
    }

    /// @dev XYZ are deposited through `fallback()` when calling this function
    function claimRewards() public {
        total_staked_amount += stakingXYZ.claimReward();
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

    /// @dev Transfer rewards deposited in this contract, when unstaking XYZ
    function withdraw(uint256 ID) public nonReentrant {
        uint256 received = (stakingXYZ.withdrawUndelegated(ID) * rate()) /
            1e18;

        // update total staked here as undelegate(...) can potentially fail even
        // if `unlock(...)` does not fail
        total_staked_amount -= received;

        lastUnlockID[msg.sender] = 0;

        (bool sent, ) = payable(msg.sender).call{value: received}(
            "sXYZ withdrawl"
        );
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev As a cToken, sYXZ price always increases over time which means: 1 sXYZ > 1 XYZ
     * @return rate of 1 sXYZ against XYZ
     */
    function rate() public view returns (uint256) {
        return
            totalSupply() == 0
                ? 1e18
                : total_staked_amount / totalSupply() / 1e18;
    }
}
