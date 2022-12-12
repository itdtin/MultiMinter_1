import {ethers} from "hardhat";
import {saveJSON} from "./utils";

async function main() {
  const nftPrice = ethers.utils.parseEther("0.001")
  const Nft = await ethers.getContractFactory("MyERC721");
  const nft = await Nft.deploy();
  await nft.deployed();

  const Minter = await ethers.getContractFactory("MultiMinter");
  const minter = await Minter.deploy(nft.address, nftPrice, 10);
  await minter.deployed();
  await saveJSON({"minter": minter.address, "nft": nft.address}, "addresses")
  console.log(`Minter deployed on address ${minter.address}`)

  await (await minter.deployClones(5)).wait();
  await (await minter.fundClones(5, 1, {value: ethers.utils.parseEther("0.07")})).wait();
  console.log(`Clones deployed `)

  let ABI = ["function purchase(uint256) payable"];
  let iface = new ethers.utils.Interface(ABI);
  let data = iface.encodeFunctionData("purchase", [1]);

  // ABI = ["function _minted()"];
  // iface = new ethers.utils.Interface(ABI);
  // let supplydata = iface.encodeFunctionData("_minted", []);

  await (
      await minter.hotMintWithoutIDs(5, 1, 1, data, {
        gasLimit: 1083994,
      })
  ).wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
