import { ethers } from "hardhat";

describe("multimint", () => {
  it("721", async () => {
    const price = ethers.utils.parseEther("0.001")
    const NFT = await ethers.getContractFactory("MyERC721");
    const nft = await NFT.deploy();
    await nft.deployed();
    const Minter = await ethers.getContractFactory("MultiMinter");
    const minter = await Minter.deploy(nft.address, price, 10044);
    await minter.deployed();

    await (await minter.deployClones(10)).wait();
    await (await minter.fundClones(10, 2, { value: ethers.utils.parseEther("10") })).wait();
    let ABI = ["function purchase(uint256) payable"];
    let iface = new ethers.utils.Interface(ABI);
    let data = iface.encodeFunctionData("purchase", [1]);

    await (
      await minter.hotMintWithoutIDs(10, 1, 1, data, {
        gasLimit: 1083994,
      })
    ).wait();

  });
});
