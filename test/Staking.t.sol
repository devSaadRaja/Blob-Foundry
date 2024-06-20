// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RewardToken} from "../src/RewardToken.sol";
import {Staking} from "../src/staking/Staking.sol";

import {Test, console} from "forge-std/Test.sol";

interface IBLOB {
    function addTaxExempts(address) external;
}

contract StakingTest is Test {
    uint256 public E18 = 10 ** 18;
    uint256 public SECONDS_IN_A_DAY = 86400;
    uint256 public SECONDS_IN_AN_HOUR = 3600;

    address public owner = 0x6bC42c45aE8108CeE5205E0Ec7757a3e3E88131E;
    address public user1 = 0xE536B4D7cf1e346D985cEe807e16B1b11B019976;
    address public user2 = 0x599A67bE30BF26e71c641de4fDc05Ac4c519949B;
    address public user3 = 0x102d0aBf6340aBF0fB194DBB0a19A793fE4ca268;

    address public BLOB = 0x2eA6CC1ac06fdC01b568fcaD8D842DEc3F2CE1aD;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public DATETIME = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public TREASURY = 0x35D9466FFa2497fa919203809C2F150F493A0f73;

    RewardToken public sBlob;
    Staking public staking;

    // ==================== SETUP ==================== //

    function setUp() public {
        vm.startPrank(owner); // // //------- ---------

        sBlob = new RewardToken();
        staking = new Staking(address(sBlob));

        sBlob.initialize(address(staking));

        IBLOB(BLOB).addTaxExempts(address(staking));

        vm.stopPrank(); // // //------- ---------

        vm.startPrank(TREASURY); // // //------- ---------
        deal(WETH, TREASURY, 1000000 ether);
        IERC20(WETH).approve(address(staking), 1000000 ether);
        staking.deposit(1000000 ether);
        vm.stopPrank(); // // //------- ---------

        vm.startPrank(owner); // // //------- ---------
        staking.initialize();
        vm.stopPrank(); // // //------- ---------

        deal(BLOB, user1, 5000000 ether);
        deal(BLOB, user2, 5000000 ether);
        deal(BLOB, user3, 5000000 ether);

        // // // ---------------------------------------- ---------

        vm.startPrank(user1);
        IERC20(BLOB).approve(address(staking), 5000000 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        IERC20(BLOB).approve(address(staking), 5000000 ether);
        vm.stopPrank();
        vm.startPrank(user3);
        IERC20(BLOB).approve(address(staking), 5000000 ether);
        vm.stopPrank();
    }

    // ==================== TEST-CASES ==================== //

    function testSBLOBDeploy() external {
        console.log("should correctly construct staking reward token");

        assertEq(sBlob.name(), "Reward Token");
        assertEq(sBlob.symbol(), "sBlob");
        assertEq(sBlob.decimals(), 18);
    }

    function testStakingDeploy() external {
        console.log("should correctly construct staking contract");

        assertEq(staking.BLOB(), BLOB);
        assertEq(staking.SBLOB(), address(sBlob));
        assertEq(sBlob.decimals(), 18);
        assertEq(staking.getEpochDetails(1).staked, 0);
        assertEq(staking.getEpochDetails(1).duration, SECONDS_IN_AN_HOUR * 4);
        assertEq(
            staking.amountPerEpoch(),
            staking.getEpochDetails(1).distribute
        );
        assertEq(
            staking.getEpochDetails(1).end,
            block.timestamp + SECONDS_IN_AN_HOUR * 4
        );

        console.log(staking.amountPerEpoch());
        console.log(staking.getEpochDetails(1).distribute);
    }

    function testStake() external {
        console.log("should update balances after stake");

        vm.startPrank(user1);
        staking.stake(1000 ether);
        staking.stake(500 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        staking.stake(500 ether);
        vm.stopPrank();

        assertEq(IERC20(BLOB).balanceOf(address(staking)), 2000 ether);
        assertEq(IERC20(sBlob).balanceOf(user1), 1500 ether);

        assertEq(staking.totalStaked(), 2000 ether);
        assertEq(staking.totalStakesByUser(user1), 1500 ether);
        assertEq(staking.totalStakesByUser(user2), 500 ether);

        assertEq(staking.getStakeDetails(user1)[0].balance, 1000 ether);
        assertEq(staking.getStakeDetails(user1)[1].balance, 500 ether);

        assertEq(staking.getStakeDetails(user1)[0].epochNumber, 1);
        assertEq(staking.getStakeDetails(user1)[1].epochNumber, 1);

        assertEq(staking.getStakeDetails(user1)[0].start, block.timestamp);
        assertEq(staking.getStakeDetails(user1)[1].start, block.timestamp);

        assertEq(
            staking.getStakeDetails(user1)[0].expiry,
            block.timestamp + SECONDS_IN_A_DAY * 4
        );
        assertEq(
            staking.getStakeDetails(user2)[0].expiry,
            block.timestamp + SECONDS_IN_A_DAY * 4
        );
    }

    function testTokenTransfer() external {
        console.log(
            "should not let transfer reward tokens other than to/from staking"
        );

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        vm.stopPrank();

        // transfer to other user
        vm.startPrank(user1);
        vm.expectRevert("Can't transfer sBlob");
        IERC20(sBlob).transfer(user2, 10 ether);
        assertEq(IERC20(sBlob).balanceOf(user2), 0);
        vm.stopPrank();

        // transfer to staking
        vm.startPrank(user1);
        IERC20(sBlob).transfer(address(staking), 1000 ether);
        assertEq(IERC20(sBlob).balanceOf(user1), 0);
        assertEq(IERC20(sBlob).balanceOf(address(staking)), 10000000000 ether);
        vm.stopPrank();
    }

    function testUnstakeMore() external {
        console.log("should revert if unstaking more than staked");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        IERC20(sBlob).approve(address(staking), 1000 ether);
        vm.stopPrank();

        _passTime(SECONDS_IN_A_DAY * 4);

        vm.startPrank(user1);
        staking.unstake(500 ether);
        vm.expectRevert("Invalid amount");
        staking.unstake(600 ether, 0);
        vm.stopPrank();
    }

    function testUnstake() external {
        console.log("should update balances after unstake some tokens");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        staking.stake(500 ether);
        IERC20(sBlob).approve(address(staking), 1500 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // unstaking
        vm.startPrank(user1);
        staking.unstake(500 ether);
        staking.unstake(250 ether);
        staking.unstake(500 ether);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 250 ether);
        assertEq(staking.totalStakesByUser(user1), 250 ether);

        assertEq(IERC20(BLOB).balanceOf(user1), 4999750 ether);
        assertEq(IERC20(BLOB).balanceOf(address(staking)), 250 ether);

        assertEq(IERC20(sBlob).balanceOf(user1), 250 ether);

        assertEq(staking.getStakeDetails(user1)[0].balance, 250 ether);

        vm.startPrank(user1);
        staking.unstakeAll();
        vm.stopPrank();

        /// ----------------------------------
        /// ----------------------------------

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        staking.stake(500 ether);
        IERC20(sBlob).approve(address(staking), 1500 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // unstaking
        vm.startPrank(user1);
        staking.unstake(500 ether, 0);
        staking.unstake(250 ether, 1);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 750 ether);
        assertEq(staking.totalStakesByUser(user1), 750 ether);

        assertEq(IERC20(BLOB).balanceOf(user1), 4999250 ether);
        assertEq(IERC20(BLOB).balanceOf(address(staking)), 750 ether);

        assertEq(IERC20(sBlob).balanceOf(user1), 750 ether);

        assertEq(staking.getStakeDetails(user1)[0].balance, 500 ether);
        assertEq(staking.getStakeDetails(user1)[1].balance, 250 ether);
    }

    function testUnstakeLength() external {
        console.log("should remove stake position after unstake");

        vm.startPrank(user1);

        // staking
        staking.stake(500 ether);
        staking.stake(515 ether);
        IERC20(sBlob).approve(address(staking), 1015 ether);

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // unstaking
        assertEq(staking.getStakeDetails(user1).length, 2);
        staking.unstake(250 ether);
        assertEq(staking.getStakeDetails(user1).length, 2);
        staking.unstake(255 ether);
        assertEq(staking.getStakeDetails(user1).length, 1);

        staking.unstakeAll();

        vm.stopPrank();

        /// ----------------------------------
        /// ----------------------------------

        vm.startPrank(user1);

        // staking
        staking.stake(500 ether);
        staking.stake(515 ether);
        IERC20(sBlob).approve(address(staking), 1500 ether);

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // unstaking
        assertEq(staking.getStakeDetails(user1).length, 2);
        staking.unstake(250 ether, 0);
        assertEq(staking.getStakeDetails(user1).length, 2);
        staking.unstake(250 ether, 0);
        assertEq(staking.getStakeDetails(user1).length, 1);
        staking.unstake(515 ether, 0);
        assertEq(staking.getStakeDetails(user1).length, 0);

        vm.stopPrank();
    }

    function testUnstakeAll() external {
        console.log("should update balances after unstake all tokens");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        staking.stake(500 ether);
        IERC20(sBlob).approve(address(staking), 1500 ether);
        vm.stopPrank();

        vm.startPrank(user2);
        staking.stake(500 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // starting next epoch
        staking.startNextEpoch();

        // unstaking
        vm.startPrank(user1);
        staking.unstakeAll();
        vm.stopPrank();

        assertEq(staking.totalStaked(), 500 ether);
        assertEq(staking.totalStakesByUser(user1), 0);
        assertEq(staking.totalStakesByUser(user2), 500 ether);

        assertEq(staking.getStakeDetails(user1).length, 0);
        assertEq(IERC20(sBlob).balanceOf(user1), 0);
        assertEq(IERC20(BLOB).balanceOf(user1), 5000000 ether);
        assertEq(IERC20(BLOB).balanceOf(address(staking)), 500 ether);
    }

    function testNoClaim() external {
        console.log("should not let claim before warmup period ends");

        vm.startPrank(user1);
        staking.stake(1000 ether);
        vm.expectRevert("Warmup Period not Ended!");
        staking.claimReward(0);
        vm.stopPrank();
    }

    function testClaim() external {
        console.log("should update values after claim rewards");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        staking.stake(500 ether);
        vm.stopPrank();
        vm.startPrank(user3);
        staking.stake(500 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // starting next epoch
        staking.startNextEpoch();

        vm.startPrank(user1);
        staking.claimReward(0); // user 1 rewards
        assertEq(staking.totalRewardsPaid(), 1366120218579234972000);
        assertEq(IERC20(WETH).balanceOf(user1), 1366120218579234972000);
        vm.stopPrank();

        vm.startPrank(user2);
        staking.claimReward(0); // user 2 rewards
        assertEq(staking.totalRewardsPaid(), 2049180327868852458000);
        assertEq(IERC20(WETH).balanceOf(user2), 683060109289617486000);
        vm.stopPrank();

        vm.startPrank(user3);
        staking.claimReward(0); // user 3 rewards
        assertEq(staking.totalRewardsPaid(), 2732240437158469944000);
        assertEq(IERC20(WETH).balanceOf(user3), 683060109289617486000);
        vm.stopPrank();
    }

    function testClaimAll() external {
        console.log("should update values after claimAll rewards");

        // staking
        vm.startPrank(user1);
        staking.stake(500 ether);
        staking.stake(500 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        staking.stake(250 ether);
        staking.stake(250 ether);
        vm.stopPrank();
        vm.startPrank(user3);
        staking.stake(250 ether);
        staking.stake(250 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // starting next epoch
        staking.startNextEpoch();

        vm.startPrank(user1);
        staking.claimAll(); // user 1 rewards
        assertEq(staking.totalRewardsPaid(), 1366120218579234972000);
        assertEq(IERC20(WETH).balanceOf(user1), 1366120218579234972000);
        vm.stopPrank();

        vm.startPrank(user2);
        staking.claimAll(); // user 2 rewards
        assertEq(staking.totalRewardsPaid(), 2049180327868852458000);
        assertEq(IERC20(WETH).balanceOf(user2), 683060109289617486000);
        vm.stopPrank();

        vm.startPrank(user3);
        staking.claimAll(); // user 3 rewards
        assertEq(staking.totalRewardsPaid(), 2732240437158469944000);
        assertEq(IERC20(WETH).balanceOf(user3), 683060109289617486000);
        vm.stopPrank();
    }

    function testReinvest() external {
        console.log("should update values after reinvest");

        // staking
        vm.startPrank(user1);
        staking.stake(500 ether);
        staking.stake(500 ether);
        staking.stake(500 ether);
        staking.stake(500 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // starting next epoch
        staking.startNextEpoch();

        // reinvest
        vm.startPrank(user1);
        staking.reinvest();
        vm.stopPrank();

        assertEq(staking.getStakeDetails(user1).length, 5);
        assertEq(staking.totalStaked(), 5870437122828594921194567342);
        assertEq(staking.totalRewardsPaid(), 2732240437158469944000);
    }

    function testNextEpochRewards() external {
        console.log("should start next epoch and update values accordingly");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        vm.stopPrank();
        vm.startPrank(user2);
        staking.stake(1000 ether);
        vm.stopPrank();

        // warmup period passing
        _passTime(SECONDS_IN_A_DAY * 4);

        // starting next epoch
        staking.startNextEpoch();

        assertEq(staking.currentEpoch(), 2);
        assertEq(staking.getEpochDetails(2).staked, 0);
        assertEq(staking.getEpochDetails(2).duration, SECONDS_IN_AN_HOUR * 4);
        assertEq(staking.getEpochDetails(2).distribute, 2732240437158469945355);
        assertEq(
            staking.getEpochDetails(2).end,
            block.timestamp + SECONDS_IN_AN_HOUR * 4
        );
    }

    function testNextMonth() external {
        console.log("should update values on 1st of every month");

        // staking
        vm.startPrank(user1);
        staking.stake(1000 ether);
        vm.stopPrank();

        staking.startNextEpoch();

        _passTime(SECONDS_IN_AN_HOUR * 4);
        staking.startNextEpoch();

        vm.startPrank(TREASURY); // // //------- ---------
        deal(WETH, TREASURY, 1000000 ether);
        IERC20(WETH).approve(address(staking), 1000000 ether);
        staking.deposit(1000000 ether);
        vm.stopPrank(); // // //------- ---------

        _passTime(SECONDS_IN_AN_HOUR * 17); // ---
        staking.startNextEpoch();

        assertEq(IERC20(WETH).balanceOf(address(TREASURY)), 0);

        assertEq(staking.currentEpoch(), 3);
        assertEq(staking.getEpochDetails(1).staked, 1000 ether);
        assertEq(staking.getEpochDetails(2).staked, 1000 ether);
        assertEq(staking.getEpochDetails(3).staked, 0);

        assertEq(
            staking.getEpochDetails(1).distribute,
            2732240437158469945355,
            "1"
        );
        assertEq(
            staking.getEpochDetails(2).distribute,
            2732240437158469945355,
            "2"
        );
        assertEq(
            staking.getEpochDetails(3).distribute,
            2732240437158469945355,
            "3"
        );
    }

    // ==================== UTILS ==================== //

    // pass time
    function _passTime(uint256 sec) internal {
        vm.warp(block.timestamp + sec);
    }
}
