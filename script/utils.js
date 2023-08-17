const { ethers } = require("hardhat");

const solveChallenge = async (challengeNumber, sender, difficulty) => {
  let nonce = 1;
  let hash;
  while (true) {
    hash = ethers.solidityPackedKeccak256(
      ["bytes32", "address", "uint"],
      [challengeNumber, sender, nonce]
    );

    if (parseInt(hash) < difficulty) {
      break;
    }
    nonce = ethers.hexlify(ethers.randomBytes(32));
  }

  return [nonce, hash];
};

module.exports = {
  solveChallenge,
};
