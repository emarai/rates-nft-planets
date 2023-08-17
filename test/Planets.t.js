const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");
const { solveChallenge } = require("../script/utils");

const BASE_REWARD = 250n;

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
    console.log(hashCheck)
    expect(hashCheck).to.equal(hash);

    await planets.mint(nonce, hash);
    const ownerToken = await planets.ownerOf("1");
    expect(ownerToken).to.equal(owner.address);

    // rates

    hash = BigInt(hash);
    const rts = hash & 0x3e8n;
    const prts = BASE_REWARD + ((hash >> (12n * 1n)) & 0x3e8n);
    const arts = BASE_REWARD + ((hash >> (12n * 2n)) & 0x3e8n);
    const mrts = BASE_REWARD + ((hash >> (12n * 3n)) & 0x3e8n);
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

    expect(rts).to.equal(rtsContract);
    expect(prts).to.equal(prtsContract);
    expect(arts).to.equal(artsContract);
    expect(mrts).to.equal(mrtsContract);
    expect(x).to.equal(xContract);
    expect(y).to.equal(yContract);

    console.log("rts", rts);
    console.log("prts", prts);
    console.log("arts", arts);
    console.log("mrts", mrts);
    console.log("x", x);
    console.log("y", y);
  });
});
