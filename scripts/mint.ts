import {ethers} from "hardhat";
import {loadMyMinter, saveJSON} from "./utils";


async function mint() {
  const nftPrice = ethers.utils.parseEther("0.002")
  const nftAddress = "0xB5a5756708381154D0e0A513E26b990eaa671900"
  const supply = 10000000000000
  const minterAddr = (await loadMyMinter()).minter

  const txPerCall = 1
  const nftPerWallet = 1
  const clonesAmount = 5
  const gasLimitMint = 1083994
  //
  const minter = await ethers.getContractAt("MultiMinter", minterAddr)
  await minter.setDropInfo(nftPrice, nftAddress, supply)
  console.log(`Minter deployed on address ${minter.address}`)
  const clonesDeployed = (await minter.clonesLength()).toNumber()
  const clonesToDeploy = clonesAmount - clonesDeployed > 0 ? clonesAmount - clonesDeployed : 0

  if (clonesToDeploy > 0) {
    await (await minter.deployClones(clonesToDeploy)).wait();
    console.log(`Clones deployed ${clonesToDeploy}`)
  }
  const gasPrice = await ethers.getDefaultProvider().getGasPrice();
  const gasUnits = await minter.estimateGas.fundClones(clonesAmount, nftPerWallet, {value: nftPrice.mul(clonesAmount), gasLimit: 200000});
  const transactionFee = gasPrice.mul(gasUnits);
  console.log(transactionFee.toString())
  const value = nftPrice.mul(clonesAmount).add(transactionFee)
  await (await minter.fundClones(clonesAmount, nftPerWallet, {value: value})).wait();

  let ABI = ["function mint(uint256) payable"];
  let iface = new ethers.utils.Interface(ABI);
  let data = iface.encodeFunctionData("mint", [nftPerWallet]);

  // ABI = ["function _minted()"]; // ToDo uncomment and fill this block if invoke mint with id
  // iface = new ethers.utils.Interface(ABI);
  // let supplydata = iface.encodeFunctionData("_minted", []);
  //
  const tx = await (
      await minter.hotMintWithoutIDs(clonesAmount, txPerCall, nftPerWallet, data, {
        gasLimit: gasLimitMint,
      })
  ).wait();
  await saveJSON(tx?.events || "", "events")

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
mint().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
