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
    goerli: {
      url: "https://thrilling-convincing-fire.ethereum-goerli.quiknode.pro/2dccda67a7706727111291f27b483c645ce05f77",
      accounts: [pk],
    },
  },

};

export default config;
