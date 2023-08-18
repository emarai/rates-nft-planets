const hre = require("hardhat");
const { ethers } = require("hardhat");
const { solveChallenge } = require("./utils");

async function main() {
  const [owner] = await ethers.getSigners();

  const Planets = await ethers.getContractFactory("Planets");
  const planets = await Planets.attach(
    "0xd3612Eb225F4d814b1Fd7298BFBEb8F7d8Bc6CBb"
  );

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

  // const hashCheck = await planets.checkHash(nonce, hash);
  // if(hashCheck != hash) {
  //   console.error("hash different")

  // };

  await planets.mint(nonce, hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
