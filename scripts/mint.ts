import {ethers} from "hardhat";
import {saveJSON} from "./utils";


async function main() {
  const nftPrice = ethers.utils.parseEther("0.002")
  const nftAddress = "0xB5a5756708381154D0e0A513E26b990eaa671900"
  const minterAddress = "0x470193Cb69D21C386066AC8Da6b98fda58EcF16c"
  const clonesAmount = 3
  const gasLimit = 50000

  const minter = await ethers.getContractAt("MultiMinter", minterAddress)
  // await minter.setDropInfo(nftPrice, nftAddress, 10000000000000)
  await saveJSON({"minter": minter.address, "nft": nftAddress}, "addresses")
  console.log(`Minter deployed on address ${minter.address}`)
  let clonesToDeploy = 0;
  for (let counterClones = 0; counterClones < clonesAmount; counterClones += 1) {
    try {
      await minter.clones(counterClones)
    } catch (e) {
      clonesToDeploy += 1
      console.log(`Need deploy ${clonesToDeploy} clones`)
    }
  }
  if (clonesToDeploy > 0) {
    await (await minter.deployClones(clonesToDeploy)).wait();
    console.log(`Clones deployed ${clonesToDeploy}`)
  }
  const gasPrice = await ethers.getDefaultProvider().getGasPrice();
  const gasUnits = await minter.estimateGas.fundClones(clonesAmount, 1, {value: nftPrice.mul(6)});
  const transactionFee = gasPrice.mul(gasUnits);
  // const value = await estimateFeeFund(minter, [clonesAmount, 1])
  console.log(transactionFee.toString())
  // const value = nftPrice.mul(clonesAmount).add((await ethers.provider.getGasPrice()).mul(gasLimit))
  // await (await minter.fundClones(clonesAmount, 1, {value: value, gasLimit: gasLimit})).wait();
  //
  // let ABI = ["function Mint(uint256) payable"];
  // let iface = new ethers.utils.Interface(ABI);
  // let data = iface.encodeFunctionData("Mint", [1]);
  //
  // // ABI = ["function _minted()"];
  // // iface = new ethers.utils.Interface(ABI);
  // // let supplydata = iface.encodeFunctionData("_minted", []);
  //
  // await (
  //     await minter.hotMintWithoutIDs(clonesAmount, 1, 1, data, {
  //       gasLimit: 1083994,
  //     })
  // ).wait();

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
