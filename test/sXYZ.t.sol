// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import {IStakingXYZ} from "../src/IStakingXYZ.sol";

import {sXYZ} from "../src/sXYZ.sol";

contract sXYZ_Test is Test {
    IStakingXYZ public stakingXYZ;
    address public validator;

    sXYZ public sxyz;

    uint256 public relayerFee = 0.01 ether;

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
        // // when StakingXYZ will be implemented, sXYZ should receive 10 ether from StakingXYZ, through `fallback()`
        // assertEq(payable(address(sxyz)).balance, 10 ether);
    }

    function test_deposit() public {
        assertEq(payable(address(stakingXYZ)).balance, 0);

        vm.mockCall(
            address(stakingXYZ),
            abi.encodeWithSelector(stakingXYZ.getRelayerFee.selector),
            abi.encode(relayerFee)
        );

        sxyz.deposit{value: 10 ether}();

        uint256 netDeposit = 10 ether - relayerFee;

        assertEq(sxyz.total_staked_amount(), netDeposit);
        assertEq(sxyz.balanceOf(address(this)), netDeposit);
        assertEq(payable(address(stakingXYZ)).balance, 10 ether);
    }

    function testRevert_deposit_When_LowerThanRelayerFee() public {
        vm.mockCall(
            address(stakingXYZ),
            abi.encodeWithSelector(stakingXYZ.getRelayerFee.selector),
            abi.encode(relayerFee)
        );

        vm.expectRevert("sXYZ: deposit <= relayerFee");
        sxyz.deposit{value: relayerFee - 1}();
    }
}
