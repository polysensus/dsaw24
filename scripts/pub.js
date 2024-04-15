import {ethers} from "ethers";

const key = process.argv[2]

const wallet = new ethers.Wallet(key);
const address = ethers.utils.computeAddress(wallet.publicKey);
console.log(address)
