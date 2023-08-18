const { ethers, upgrades } = require("hardhat");

async function main() {
  const Planets = await ethers.getContractFactory("Planets");
  const planets = await upgrades.deployProxy(Planets, [
    "RatesPlanets",
    "RP",
    "https://api.ratesprotocol.com/assets/",
  ]);
  await planets.waitForDeployment();
  console.log("Planets deployed to:", await planets.getAddress());
}

main();
