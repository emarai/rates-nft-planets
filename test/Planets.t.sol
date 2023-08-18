// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Planets.sol";

contract PlanetsTest is Test {
    Planets private planetsContract;
    address alice = makeAddr("alice");

    function setUp() public {
        planetsContract = new Planets();
        planetsContract.initialize("RatesPlanets", "RP", "");
    }

    function solveChallenge(
        bytes32 challengeNumber,
        address sender,
        uint256 difficulty
    ) public pure returns (uint256 nonce) {
        while (true) {
            nonce += 1;
            // console.log("nonce generated %s", nonce);

            uint256 digestResult = uint256(
                keccak256(abi.encode(challengeNumber, sender, nonce))
            );

            if (digestResult < uint256(difficulty)) {
                break;
            }
        }

        return nonce;
    }

    function hash(
        uint256 nonce,
        address sender,
        bytes32 challengeNumber
    ) public pure returns (bytes32 digestResult) {
        digestResult = keccak256(abi.encode(challengeNumber, sender, nonce));
        return digestResult;
    }

    function test_MintWorks() public {
        bytes32 currentChallenge = planetsContract.getChallengeNumber();
        uint256 miningDifficulty = planetsContract.getMiningDifficulty();

        console.log("challenge %s", uint256(currentChallenge));

        uint256 nonce = solveChallenge(
            currentChallenge,
            alice,
            miningDifficulty
        );
        bytes32 digest = hash(nonce, alice, currentChallenge);
        console.log("nonce %s", nonce);
        console.log("digest %s", uint256(digest));

        vm.prank(alice);
        assertEq(planetsContract.checkHash(nonce, digest), digest);

        vm.prank(alice);
        planetsContract.mint(nonce, digest);
    }
}
