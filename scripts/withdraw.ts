import hre, {ethers} from "hardhat";
import {checkEvents, doViaChunks, loadMyMinter} from "./utils";
import fs from "fs";
import {BigNumber} from "ethers";

interface WithdrawData {
    cloneAddress: string;
    tokenIds: [number];
}

async function withdraw() {
    const [signer] = await hre.ethers.getSigners()
    const nftAddress = "0xB5a5756708381154D0e0A513E26b990eaa671900"
    const txHash = "0xe0d4e3cd766e6035ee07b1ba52fbd1a0c1b71cec2e48348362364484dbcd917c"
    const nftContract = await ethers.getContractAt(JSON.parse(fs.readFileSync(process.cwd() + "/scripts/abi.json").toString()), nftAddress)
    const receipt = await ethers.provider.getTransactionReceipt(txHash);
    // @ts-ignore
    const transferTopic = nftContract.filters.Transfer().topics[0]
    const minterAddr = (await loadMyMinter()).minter
    const minter = await ethers.getContractAt("MultiMinter", minterAddr)
    console.log(`Minter deployed on address ${minter.address}`)
    const clones = {};
    const cloneLength = await minter.clonesLength()
    while (cloneLength.toNumber() > Object.keys(clones).length) {
        try {
            // @ts-ignore
            clones[(await minter.clones(Object.keys(clones).length)).toLowerCase()] = []
        } catch (e) {
            console.log(`Can't get clone\n${e}`)
        }
    }
    const apiKey = "CG8YZYQKX35N1USAXTSJNINCZA2WV2S7DD"
    const apiUrl = "https://api.etherscan.io/api"
    const finalEvents = await checkEvents(apiUrl, apiKey, nftAddress, transferTopic, receipt.blockNumber - 1)

    async function func(event: any) {
        const address = ethers.utils.defaultAbiCoder.decode(["address"], event['topics'][2])[0].toLowerCase()

        const index = Object.keys(clones).indexOf(address)
        if (index != -1) {
            const nftIds: [BigNumber] = [
                ethers.utils.defaultAbiCoder.decode(["uint256"], event['topics'][3])[0].toNumber()
            ]
            // @ts-ignore
            clones[address] = clones[address].concat(nftIds)
        }
    }
    await doViaChunks(finalEvents, func)
    const withdrawDatas = [] as WithdrawData[]
    for (const [cloneAddress, nftIds] of Object.entries(clones)) {
        const withdrawData = {
            cloneAddress: cloneAddress,
            tokenIds: nftIds
        } as WithdrawData
        withdrawDatas.push(withdrawData)
    }

    await minter.massWithdrawNft(withdrawDatas, nftAddress, signer.address)
    await minter.withdrawEthClones(signer.address)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
withdraw().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
