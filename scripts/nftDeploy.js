// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const mysql = require('mysql2/promise');

async function main() {
  try {
    const NFT = await hre.ethers.getContractFactory("NFT");
    const nft = await NFT.deploy();
    await nft.deployed();
    console.log("NFT deployed to: ", nft.address);
    const abiRaw = require('../artifacts/contracts/NFT.sol/NFT.json');
    const abi = JSON.stringify(abiRaw.abi);
    console.log(abi);
    /* const connection = await mysql.createConnection({
      host: process.env.DB_ENDPOINT || 'localhost',
      user: process.env.DB_USERNAME || 'petronft2',
      database: process.env.DB_NAME || 'marketplace',
      password: process.env.DB_PASSWORD || 'Ovni67,.'
    });

    const result = await connection.query(`insert into collections (address, abi, red, createdAt, updatedAt) 
        values ('${nft.address}', '${abi}', ${nft.deployTransaction.chainId}, NOW(), NOW())`);  */
  } catch (error) {
    console.log(error);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
