// scripts/upgrade_Token.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const LockV2 = await ethers.getContractFactory('Lock');
  console.log('Upgrading Lock...');
  await upgrades.upgradeProxy('0xEe89497CB25A2D57B63c7aF35DC194Da04Eb55ed', LockV2);
  console.log('Lock upgraded');
}

main();