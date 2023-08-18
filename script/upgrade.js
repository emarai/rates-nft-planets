const { ethers, upgrades } = require("hardhat");

async function main() {
  const ADDRESS = "0xd3612Eb225F4d814b1Fd7298BFBEb8F7d8Bc6CBb";
  const Planets = await ethers.getContractFactory("Planets");
  const planets = await upgrades.upgradeProxy(ADDRESS, Planets);
  console.log("Planets upgraded");

  await planets.resetDifficulty();
}

main();
