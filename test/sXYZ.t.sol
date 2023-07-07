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

        uint256 netDeposit = _deposit_10_XYZ();

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

    function test_unlock_all() public {
        uint256 netDeposit = _deposit_10_XYZ();

        uint256 ID = _unlock_XYZ(netDeposit);

        assertEq(sxyz.balanceOf(address(this)), 0);
        assertEq(sxyz.lastUnlockID(address(this)), ID);
    }

    function test_unlock_half() public {
        uint256 netDeposit = _deposit_10_XYZ();
        uint256 amount = netDeposit / 2;

        uint256 ID = _unlock_XYZ(amount);

        assertEq(sxyz.balanceOf(address(this)), netDeposit / 2);
        assertEq(sxyz.lastUnlockID(address(this)), ID);
    }

    function testRevert_unlock_When_PendingUnDelegation() public {
        uint256 netDeposit = _deposit_10_XYZ();
        uint256 amount = netDeposit / 2;

        _unlock_XYZ(amount);

        vm.expectRevert("sXYZ: pending undelegation");
        sxyz.unlock(amount);
    }

    function _deposit_10_XYZ() internal returns (uint256 netDeposit) {
        vm.mockCall(
            address(stakingXYZ),
            abi.encodeWithSelector(stakingXYZ.getRelayerFee.selector),
            abi.encode(relayerFee)
        );

        sxyz.deposit{value: 10 ether}();

        return 10 ether - relayerFee;
    }

    function _unlock_XYZ(uint256 amount) internal returns (uint256 ID) {
        ID = uint256(
            keccak256(
                abi.encodePacked(address(stakingXYZ), address(this), amount)
            )
        );

        vm.mockCall(
            address(stakingXYZ),
            abi.encodeWithSelector(stakingXYZ.undelegate.selector),
            abi.encode(ID)
        );

        sxyz.unlock(amount);
    }
}
