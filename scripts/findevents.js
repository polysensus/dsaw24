import fs from "fs";
import {ethers} from "ethers";

function main() {

  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    console.log('rpc-url from-address interface-id')
    process.exit(0);
  }
  const rpcUrl = process.argv[2];
  const address = process.argv[3];
  const fileName = process.argv[4];
  const eventName = process.argv[5];

  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
  const iface = readInterface(fileName);
  const event = iface.getEvent(eventName)
  const topic = ethers.utils.id(event.format());
  console.log(event.format(), ' ', topic);
  const c = new ethers.Contract(address, iface, provider);

  const filter = {
    address,
    // address: null,
    topics: [topic]
  }

  c.queryFilter(filter, "0x0").then(logs => {
    for (const log of logs) {
      console.log(JSON.stringify(log));
      const parsed = iface.parseLog(log)
      console.log(JSON.stringify(parsed));
      // // Decode log data using the event fragment
      // const decodedLog = i.decodeEventLog(eventName, log.data, log.topics.slice(1));
      // console.log(decodedLog);
    }
  });
}

export function  readInterface(filename) {
    const abi = readJson(filename)?.["abi"];
    if (abi == null) return null;
    return new ethers.utils.Interface(abi);
}

export function signatureSelector(signature) {
  return ethers.utils
    .keccak256(ethers.utils.toUtf8Bytes(signature))
    .slice(0, 2 + 8);
}

export function readJson(fileName) {
    const content = fs.readFileSync(fileName, "utf-8");
    try {
      return JSON.parse(content);
    } catch (err) {
      console.error(`failed to parse ${fileName}: ${err}`)
      if (this.r) this.r.info();
      return null;
    }
}

main();
