import "@nomicfoundation/hardhat-chai-matchers";
import "@nomiclabs/hardhat-ethers";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const { pk } = require("./wallets.json");

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.14",
    settings: {
      optimizer: {
        enabled: true,
        runs: 99999,
      },
    },
  },
  networks: {
    eth: {
      url: "https://eth-mainnet.g.alchemy.com/v2/00W7G2cA4NdHJYk31uIzk5h_YFwVPKZb",
      accounts: [pk],
    },
  },

};

export default config;
