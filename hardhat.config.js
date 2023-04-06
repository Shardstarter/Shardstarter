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
module.exports = {
  networks: {
    mumbai: {
      url: "https://endpoints.omniatech.io/v1/matic/mumbai/public",
      accounts: ["62868e18d46a49f045677f53867de5e11b0dc95a1fa60b47dcc829549008ecd7"] //0xecFA21cfFcb7BDeE55D137486Dea0d7984c72619
    },
    kovan: {
      url: "https://eth-kovan.alchemyapi.io/v2/4Dqo63W4vEpd0JqC-gdgxesm8m2zCI2H",
      accounts: ["62868e18d46a49f045677f53867de5e11b0dc95a1fa60b47dcc829549008ecd7"]
    },
    binance: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: ["62868e18d46a49f045677f53867de5e11b0dc95a1fa60b47dcc829549008ecd7"]
    }
  },
  solidity: "0.8.11",
};
