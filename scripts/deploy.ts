import {ethers} from "hardhat";
import {saveJSON} from "./utils";

async function main() {
  const nftPrice = ethers.utils.parseEther("0.002")
  const nftAddress = "0xB5a5756708381154D0e0A513E26b990eaa671900"

  const Minter = await ethers.getContractFactory("MultiMinter");
  const minter = await Minter.deploy(nftAddress, nftPrice, 300000);
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
