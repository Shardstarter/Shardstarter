const { ethers, upgrades } = require('hardhat');

async function main () {
  try{    
    const Lock = await ethers.getContractFactory('Lock');
    console.log('Deploying Lock...');
    const lock = await upgrades.deployProxy(Lock);
    await lock.deployed();
    console.log('Lock deployed to:', lock.address);
  }catch(err){
    console.log(err);
  }
}

main();