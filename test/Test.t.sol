// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Aggregator} from "../src/mockups/Aggregator.sol";

import {Test, console} from "forge-std/Test.sol";

contract ContractTest is Test {
    Aggregator public aggregator;

    // ==================== SETUP ==================== //

    function setUp() public {
        aggregator = new Aggregator();
    }

    // ==================== TEST 1 ==================== //

    function testPrice() external view {
        (, int256 price, , , ) = aggregator.latestRoundData();
        console.log(uint256(price));
    }
}
