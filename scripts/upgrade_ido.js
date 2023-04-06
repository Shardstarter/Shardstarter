// scripts/upgrade_Bridge.js
const { ethers, upgrades } = require('hardhat');

async function main() {
  try {
    const PoolLibrary = await ethers.getContractFactory('PoolLibrary');
    console.log('Deploying PoolLibrary...');
    const poolLibrary = await PoolLibrary.deploy(); 
    const DeployPoolLibrary = await ethers.getContractFactory('DeployPoolLibrary', {
      libraries: {
        PoolLibrary: poolLibrary.address
      }});
    console.log('Deploying DeployPoolLibrary...');
    const deployPoolLibrary = await DeployPoolLibrary.deploy(); 
    const ConfigurePoolLibrary = await ethers.getContractFactory('ConfigurePoolLibrary');
    console.log('Deploying ConfigurePoolLibrary...');
    const configurePoolLibrary = await ConfigurePoolLibrary.deploy(); 
   

    const IDOV2 = await ethers.getContractFactory('IDO', {
      libraries: {
        DeployPoolLibrary: deployPoolLibrary.address,
        ConfigurePoolLibrary:configurePoolLibrary.address
      }});
    console.log('Upgrading IDO...');
    await upgrades.upgradeProxy('0x000da6297cE5fA343Cea6D23d3e2264FE65C21be', IDOV2, { unsafeAllow:["external-library-linking"] });
    console.log('IDO upgraded');
  } catch (err) {
    console.log(err);
  }
}

main();