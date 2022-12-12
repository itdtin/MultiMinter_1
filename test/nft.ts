import { ethers } from "hardhat";

describe("multimint", () => {
  it("1155", async () => {
    const NFT = await ethers.getContractFactory("SrBananos");
    const nft = await NFT.deploy("uri", "name", "symbol");
    await nft.deployed();
    const Minter = await ethers.getContractFactory("MultiMinter");
    const minter = await Minter.deploy(nft.address, 1, 10044);
    await minter.deployed();

    await (await minter.deployClones(10)).wait();
    await (await minter.fundClones(10, 6, { value: "150" })).wait();

    let ABI = ["function MintPublic(uint256) payable"];
    let iface = new ethers.utils.Interface(ABI);
    let data = iface.encodeFunctionData("MintPublic", [2]);

    ABI = ["function _minted()"];
    iface = new ethers.utils.Interface(ABI);
    let supplydata = iface.encodeFunctionData("_minted", []);

    await (
      await minter.mintWithDeployedClones1155(10, 1, 2, data, supplydata, {
        gasLimit: 1083994,
      })
    ).wait();

    let bal = await nft._minted();
    console.log("bal = ", bal.toString());
  });
});
