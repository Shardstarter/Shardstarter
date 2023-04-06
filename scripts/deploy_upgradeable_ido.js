const { ethers, upgrades } = require('hardhat');

async function main() {
  try {
    console.log('deploying several contracts, please wait...');

    const PoolLibrary = await ethers.getContractFactory('PoolLibrary');
    const poolLibrary = await PoolLibrary.deploy();
    console.log('PoolLibrary deployed: ', poolLibrary.address);

    const DeployPoolLibrary = await ethers.getContractFactory('DeployPoolLibrary', {
      libraries: {
        PoolLibrary: poolLibrary.address
      }
    });
    const deployPoolLibrary = await DeployPoolLibrary.deploy();
    console.log('DeployPoolLibrary deployed: ', deployPoolLibrary.address);

    const ConfigurePoolLibrary = await ethers.getContractFactory('ConfigurePoolLibrary');
    const configurePoolLibrary = await ConfigurePoolLibrary.deploy();
    console.log('ConfigurePoolLibrary deployed: ', configurePoolLibrary.address);

    const IDO = await ethers.getContractFactory('IDO', {
      libraries: {
        DeployPoolLibrary: deployPoolLibrary.address,
        ConfigurePoolLibrary: configurePoolLibrary.address
      }
    });
    console.log('Deploying IDO...');
    const ido = await upgrades.deployProxy(IDO, [[0, 0, 0, 0], 0, 0],
      { initializer: 'initialize', unsafeAllow: ["external-library-linking"] });
    await ido.deployed();
    console.log('IDO deployed to:', ido.address);
  } catch (err) {
    console.log(err);
  }
}

main();