// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Feeding} from "../src/feeding/Feeding.sol";
import {Test, console} from "forge-std/Test.sol";

contract FeedingTest is Test {
    address public owner;
    address public user;

    address public BLOB;
    address public WETH;

    address public feedToken;
    address public feeding;

    function setUp() public {
        owner = 0x6bC42c45aE8108CeE5205E0Ec7757a3e3E88131E;
        user = 0x599A67bE30BF26e71c641de4fDc05Ac4c519949B;

        BLOB = 0x2eA6CC1ac06fdC01b568fcaD8D842DEc3F2CE1aD;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        feedToken = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        feeding = 0xE6B3C373380896e671c5a94E3f74cd2527324466;

        // deal(WETH, feeding, 5000 ether);

        deal(user, 10 ether);
        deal(feedToken, user, 5000 ether);

        vm.startPrank(owner);

        Feeding(feeding).addFeedToken(feedToken);

        address[] memory path = new address[](2);
        path[0] = feedToken;
        path[1] = BLOB;
        Feeding(feeding).setTokenPath(path);

        vm.stopPrank();
    }

    function testFeed() external {
        vm.startPrank(user);

        IERC20(feedToken).approve(feeding, 50 ether);
        Feeding(feeding).feed(feedToken, 0.01 ether, 150000, 1 ether);

        vm.stopPrank();

        (
            address tokenFed,
            uint256 valueFed,
            uint256 rewardMultiple,
            uint256 amount,
            uint256 start,
            uint256 vestingTime,
            bool claimed
        ) = Feeding(feeding).vestingBalances(user, 0);

        console.log(tokenFed);
        console.log(valueFed);
        console.log(rewardMultiple);
        console.log(amount);
        console.log(start);
        console.log(vestingTime);
        console.log(claimed);

        vm.warp(block.timestamp + 86405);

        vm.startPrank(user);
        Feeding(feeding).claim(0);
        vm.stopPrank();
    }
}
