// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Planets.sol";

contract NFTTest is Test {
    Planets private nft;

    function setUp() public {
        nft = new Planets("RatesPlanets", "RP", "");
    }

    function test_MintToWorks() public {}
}
