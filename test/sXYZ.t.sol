// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {IStakingXYZ} from "../src/IStakingXYZ.sol";

import {sXYZ} from "../src/sXYZ.sol";

contract sXYZ_Test is Test {
    IStakingXYZ public stakingXYZ;
    address public validator;

    sXYZ public sxyz;

    function setUp() public {
        stakingXYZ = IStakingXYZ(makeAddr("StakingXYZ"));
        validator = makeAddr("validator");

        sxyz = new sXYZ(stakingXYZ, validator);

        // to avoid vm.mockCall issue on zero bytecode address
        vm.etch(address(stakingXYZ), bytes("0x6080604052348015610010"));
    }

    function testMockCall_claimRewards() public {
        assertEq(sxyz.total_staked_amount(), 0);

        vm.mockCall(
            address(stakingXYZ),
            abi.encodeWithSelector(stakingXYZ.claimReward.selector),
            abi.encode(10 ether)
        );

        sxyz.claimRewards();
        assertEq(sxyz.total_staked_amount(), 10 ether);
    }
}
