const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");
const { solveChallenge } = require("../script/utils");

const BASE_REWARD = 250n;

describe("Planets", function () {
  async function deployContract() {
    const [owner] = await ethers.getSigners();

    const Planets = await ethers.getContractFactory("Planets");

    const planets = await Planets.deploy();

    await planets.initialize(
      "RatesPlanets",
      "RP",
      "https://ratesprotocol.com/api/json/"
    );

    return { planets, owner };
  }

  it("Should buy mining rig and mint", async function () {
    await mine(1000);

    const { planets, owner } = await deployContract();

    await planets.upgradeMiningRig(10, {
      value: ethers.parseEther((0.03 * 10).toString()),
    });

    const currentMiningRig = await planets.miningRigForAddress(owner.address);

    expect(currentMiningRig).to.equal(10);

    const miningDifficulty = await planets.getMiningDifficulty();
    const challengeNumber = await planets.getChallengeNumber();

    let [nonce, hash] = await solveChallenge(
      challengeNumber,
      owner.address,
      miningDifficulty
    );

    const hashCheck = await planets.checkHash(nonce, hash);
    expect(hashCheck).to.equal(hash);

    await planets.mint(nonce, hash);
    const ownerToken = await planets.ownerOf("1");

    // rates

    hash = BigInt(hash);
    const x = (hash >> (12n * 4n)) & 0x3e8n;
    const y = (hash >> (12n * 5n)) & 0x3e8n;
    const planetZoneMultiplier = BigInt(getPlanetZone(x, y)) * 10n;

    let rts = 100n + (hash & 0x3e8n);
    rts += (rts * 80n) / 100n;
    rts += (rts * planetZoneMultiplier) / 100n;

    const [rtsContract] = await planets.getTotalStatsPerTokenId("1");

    expect(rts).to.equal(rtsContract);
  });
  it("Should mint with correct stats", async function () {
    await mine(1000);

    const { planets, owner } = await deployContract();

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
    console.log(hashCheck);
    expect(hashCheck).to.equal(hash);

    await planets.mint(nonce, hash);
    const ownerToken = await planets.ownerOf("1");
    expect(ownerToken).to.equal(owner.address);

    // rates

    hash = BigInt(hash);
    const x = (hash >> (12n * 4n)) & 0x3e8n;
    const y = (hash >> (12n * 5n)) & 0x3e8n;

    const planetZoneMultiplier = BigInt(getPlanetZone(x, y)) * 10n;

    let rts = 100n + (hash & 0x3e8n);
    let prts = BASE_REWARD + ((hash >> (12n * 1n)) & 0x3e8n);
    let arts = BASE_REWARD + ((hash >> (12n * 2n)) & 0x3e8n);
    let mrts = BASE_REWARD + ((hash >> (12n * 3n)) & 0x3e8n);

    console.log("rts", rts);
    console.log("prts", prts);
    console.log("arts", arts);
    console.log("mrts", mrts);
    console.log("x", x);
    console.log("y", y);

    rts += (rts * planetZoneMultiplier) / 100n;
    prts += (prts * planetZoneMultiplier) / 100n;
    arts += (arts * planetZoneMultiplier) / 100n;
    mrts += (mrts * planetZoneMultiplier) / 100n;

    const [
      rtsContract,
      prtsContract,
      artsContract,
      mrtsContract,
      xContract,
      yContract,
    ] = await planets.getTotalStatsPerTokenId("1");

    console.log("rts", rts);
    console.log("prts", prts);
    console.log("arts", arts);
    console.log("mrts", mrts);
    console.log("x", x);
    console.log("y", y);
    console.log("planetZoneMultiplier", planetZoneMultiplier);

    expect(rts).to.equal(rtsContract);
    expect(prts).to.equal(prtsContract);
    expect(arts).to.equal(artsContract);
    expect(mrts).to.equal(mrtsContract);
    expect(x).to.equal(xContract);
    expect(y).to.equal(yContract);

    const miningDifficultyAfter = await planets.getMiningDifficulty();
    console.log("miningDifficultyAfter", miningDifficultyAfter);
  });

  it("getPlanetZone should work", async function () {
    const { planets, owner } = await deployContract();

    const planetZone = await planets.getPlanetZone(0, 0);

    expect(planetZone).to.equal(getPlanetZone(0n, 0n));
  });

  it("Upgrade works", async () => {
    const Planets = await ethers.getContractFactory("Planets");
    const PlanetsV2 = await ethers.getContractFactory("PlanetsV2");

    const instance = await upgrades.deployProxy(Planets, [
      "RatesPlanets",
      "RP",
      "",
    ]);
    const upgraded = await upgrades.upgradeProxy(
      await instance.getAddress(),
      PlanetsV2
    );

    const value = await upgraded.value();
    expect(value.toString()).to.equal("42");
  });

  function getPlanetZone(x, y) {
    const xFromMiddle = Math.abs(parseInt((x - 500n).toString()));
    const yFromMiddle = Math.abs(parseInt((y - 500n).toString()));

    console.log(xFromMiddle, yFromMiddle);

    const distance = Math.sqrt(xFromMiddle ** 2 + yFromMiddle ** 2);
    console.log("distance", distance);

    return parseInt(distance / 80);
  }
});
