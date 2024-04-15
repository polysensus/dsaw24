import fs from "fs";
import {ethers} from "ethers";

function main() {

  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    console.log('abi-file-name event-name')
    process.exit(0);
  }

  const fileName = process.argv[2];
  const eventPrefix = process.argv[3];

  const i = readInterface(fileName);
  const ev = i.getEvent(eventPrefix);
  const t = i.getEventTopic(eventPrefix);
  console.log(ev.format(), t);
  /*
  const sigs = Object.keys(i.events);
  for (const s of sigs) {
    if (!s.startsWith(eventPrefix))
      continue;

    const eventFragment = i.events[s];
    console.log(eventFragment.format());
    const topicHash = ethers.utils.id(ethers.utils.defaultAbiCoder.encode(eventFragment));
    console.log(topicHash)
    return
  }*/
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
