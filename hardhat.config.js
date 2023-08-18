/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
  solidity: "0.8.18",
  mocha: {
    timeout: 100000000,
  },
  networks: {
    baseGoerli: {
      url: "https://base-goerli.rpc.thirdweb.com",
      accounts: [`0x${process.env.PRIVATE_KEY}`],
      gasPrice: 1000000000,
    },
  },
  etherscan: {
    apiKey: {
      baseGoerli: "PLACEHOLDER_STRING",
    },
  },
};
