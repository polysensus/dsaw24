import {ethers} from "ethers";

const address = process.argv[2];
const rpcUrl = process.argv[3] ?? "http://localhost:8545"
const provider = new ethers.providers.JsonRpcProvider(rpcUrl);
provider.getBalance(address)
  .then(balance => {
    const eth = ethers.utils.formatEther(balance);
    console.log(`${address}: ${eth}`);
  })
  .catch(error => {
    console.error('Error:', error);
  })
