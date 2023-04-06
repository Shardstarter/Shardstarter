require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const account = process.env.key;
module.exports = {
  networks: {
    liberty2x: {
      url: "https://liberty20.shardeum.org",
      accounts: [account]
    },
    mumbai: {
      url: "https://endpoints.omniatech.io/v1/matic/mumbai/public",
      accounts: [account]
    },
    kovan: {
      url: "https://eth-kovan.alchemyapi.io/v2/4Dqo63W4vEpd0JqC-gdgxesm8m2zCI2H",
      accounts: [account]
    },
    binance: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: [account]
    }
  },
  solidity: "0.8.11",
};
