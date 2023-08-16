const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");
const { solveChallenge } = require("../script/utils");

describe("Planets", function () {
  it("Should set the right unlockTime", async function () {
    await mine(1000);

    const [owner] = await ethers.getSigners();

    const Planets = await ethers.getContractFactory("Planets");

    const planets = await Planets.deploy(
      "RatesPlanets",
      "RP",
      "https://ratesprotocol.com/api/json/"
    );

    // await planets.deployed();

    // assert that the value is correct
    const miningDifficulty = await planets.getMiningDifficulty();
    console.log("miningDifficulty", miningDifficulty);
    const challengeNumber = await planets.getChallengeNumber();
    console.log("challengeNumber", challengeNumber);

    let [nonce, hash] = await solveChallenge(
      challengeNumber,
      owner.address,
      miningDifficulty
    );
    console.log("nonce", nonce);
    console.log("hash", hash);

    const hashCheck = await planets.checkHash(nonce, hash);
    expect(hashCheck == hash);

    await planets.mint(nonce, hash);
    const ownerToken = await planets.ownerOf("1");
    expect(ownerToken == owner.address);

    // rates

    hash = BigInt(hash);
    const rts = hash & 0x3e8n;
    const prts = (hash >> (12n * 1n)) & 0x3e8n;
    const arts = (hash >> (12n * 2n)) & 0x3e8n;
    const mrts = (hash >> (12n * 3n)) & 0x3e8n;
    const x = (hash >> (12n * 4n)) & 0x3e8n;
    const y = (hash >> (12n * 5n)) & 0x3e8n;

    const [
      rtsContract,
      prtsContract,
      artsContract,
      mrtsContract,
      xContract,
      yContract,
    ] = await planets.getTotalStatsPerTokenId("1");

    expect(rts == rtsContract);
    expect(prts == prtsContract);
    expect(prts == prtsContract);
    expect(arts == artsContract);
    expect(mrts == mrtsContract);
    expect(x == xContract);
    expect(y == yContract);

    console.log("rts", rts);
    console.log("prts", prts);
    console.log("arts", arts);
    console.log("mrts", mrts);
    console.log("x", x);
    console.log("y", y);
  });
});
