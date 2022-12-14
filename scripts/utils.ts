import fs from "fs";
import axios from "axios";
import {ethers} from "hardhat";


export async function loadMyMinter() {
    const path = `./addresses/addresses.json`
    if (fs.existsSync(path)) {
        return JSON.parse(fs.readFileSync(path).toString())
    } else {
        throw Error(`Communications json file does not exists`)
    }
}


export async function saveJSON(json: object | string, fileName: string) {
    if (typeof json === "string") json = JSON.parse(json);
    const path = `./addresses/${fileName}.json`;
    fs.writeFileSync(path, JSON.stringify(json));
}

export function mergeDeep(target: any, source: any) {
    if (isObject(target) && isObject(source)) {
        for (const key in source) {
            if (isObject(source[key])) {
                if (!target[key]) Object.assign(target, { [key]: {} });
                mergeDeep(target[key], source[key]);
            } else {
                Object.assign(target, { [key]: source[key] });
            }
        }
    }
    return target;
}

export function isObject(item: any): boolean {
    return item && typeof item === "object" && !Array.isArray(item);
}

function chunkArray(myArray: any, chunk_size: number) {
    let index = 0
    const arrayLength = myArray.length
    const tempArray = []

    for (index = 0; index < arrayLength; index += chunk_size) {
        let myChunk = myArray.slice(index, index + chunk_size)
        tempArray.push(myChunk)
    }
    return tempArray
}

export async function doViaChunks(_array: any, _doFn: any, _chunkSize: number = 100) {
    try {
        let results: any = []
        const chunks = chunkArray(_array, _chunkSize)
        for (const chunk of chunks) {
            const result = await doForChunk(chunk, _doFn)
            results = results.concat(...Array(result))
        }

        async function doForChunk(_chunk: any, _doFn: any) {
            // @ts-ignore
            const data = _chunk.map(async instance => await _doFn(instance))
            return Promise.all(data)
        }
        // @ts-ignore
        results = results.filter(function(el) {
            return el !== undefined
        })
        return results
    } catch (e) { console.log(e) }
}

export async function checkEvents(apiUrl: string, apiKey: string, nftAddress: string, transferTopic: string, checkedBlock: number){
    let nextPage = true, finalEvents = [];
    while(nextPage) {
        console.log(checkedBlock)
        const events = await axios.get(
            apiUrl,
            {
                params: {
                    module: "logs",
                    action: "getLogs",
                    fromBlock: checkedBlock,
                    toBlock: "latest",
                    address: nftAddress,
                    topic0: transferTopic,
                    apikey: apiKey
                }
            }
        )
        if (events.data.status === 'fail') {
            return;
        }
        if(events.data.result.length > 0){
            if(events.data.result.length < 1000) {
                nextPage = false
            }
            checkedBlock = parseInt(events.data.result[events.data.result.length - 1]?.blockNumber, 16)
            for(const i of events.data.result) {
                finalEvents.push(i);
            }
            nextPage = false;
        }
        else {
            nextPage = false
            checkedBlock = (await ethers.provider.getBlock("latest")).number
        }
    }
    return finalEvents
}