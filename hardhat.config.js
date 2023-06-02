require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.4",
  settings: {
    optimizer: {
      enabled: true,
      runs: 1,
    } 
  },
  networks: {
    hardhat : {
      chainId: 1337,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true
    },
    binanceTestnet : {
      url: "https://data-seed-prebsc-1-s3.binance.org:8545/",
      chainId: 97,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      accounts: ['7dd21335ab282b5f07c9ec7faa3a8708f23f7473c3d8988dcee7c9b6ec3aaffb']
    },
    mumbai : {
      url: "https://matic-mumbai.chainstacklabs.com",
      chainId: 80001,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      accounts: ['7dd21335ab282b5f07c9ec7faa3a8708f23f7473c3d8988dcee7c9b6ec3aaffb']
    }
  }
};