import {ethers} from "hardhat";
import {saveJSON} from "./utils";

async function main() {
  const Minter = await ethers.getContractFactory("MultiMinter");
  const minter = await Minter.deploy();
  await minter.deployed();
  await saveJSON({"minter": minter.address}, "addresses")
  console.log(`Minter deployed on address ${minter.address}`)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
