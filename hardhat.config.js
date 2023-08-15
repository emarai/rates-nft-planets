/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-foundry");
require("@nomicfoundation/hardhat-toolbox");
module.exports = {
  solidity: "0.8.18",
  mocha: {
    timeout: 100000000,
  },
};
