// utility to find a deployed contract address
// given the public key of the deployer and the ERC 165 interface Id it is
// expected to support
//
import { ethers } from "ethers";

const wellKnownIds = {
  "721": "0x80ac58cd",
  "721M": "0x5b5e139f",
  "721E": "0x780e9d63",
  "1155": "0xd9b67a26"
  // "6551Account": "0x6faff5f1", // but this is typically CREATE 2
}

function main() {

  if (process.argv.includes("--help") || process.argv.includes("-h")) {
    console.log('rpc-url from-address interface-id')
    process.exit(0);
  }

  const rpcUrl = process.argv[2];
  const from = process.argv[3];
  let interfaceId = process.argv[4];
  if (wellKnownIds[interfaceId])
    interfaceId = wellKnownIds[interfaceId]
  const provider = new ethers.providers.JsonRpcProvider(rpcUrl);

  deriveContractAddress(provider, from, interfaceId)
    .then(addr => {
      console.log(addr);

    })
    .catch(error => {
      console.error('Error:', error);
    })
}

const ERC165ABI = [
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const erc165Interface = new ethers.utils.Interface([
  "function supportsInterface(bytes4 interfaceId) external view returns (bool)",
]);
// const erc165Interface = new ethers.utils.Interface(ERC165ABI);
const erc165InterfaceId = "0x01ffc9a7"; // The ERC165 interface ID

/**
 * Derive the address the externaly owned account last deployed a contract to.
 * Assuming that the last transaction for that address _was_ a contract
 * deployment.
 * @param {object} provider to access the chain
 * @param {string} from account that deployed the contract
 * @param {string} the interfaceId it is expected to support
 * @param {object} options. the log property is used for reporting. the nonce
 * sets the account nonce from which to start (we search down to zero)
 * TODO: Support matching the constructor signature and args to find a specific
  * deployed instance where from has deployed *many*
 */
export async function deriveContractAddress(
  provider,
  from,
  interfaceId,
  opts
) {

  let nonce = opts?.nonce ? Number.parseInt(opts?.nonce) : undefined;

  const log = opts?.console?.log ?? console.log;


  provider = provider.provider ?? provider;
  if (!nonce) {
    try {
      // nonce - 1 is the nonce of the *last* transaction on the account. We
      // scan back from here to find the most recently deployed contract
      // supporting the IDiamond interface.

      nonce = (await provider.getTransactionCount(from)) - 1;
      if (nonce < 0) {
        log(`contract not deployed, nonce is zero for ${from}`);
        return;
      }
    } catch (e) {
      log(`error getting nonce for ${from}: ${e} ${JSON.stringify(e)}`);
      return;
    }
  }

  const logmiss = (reason, nonce) => {
    // console.debug(`skipping @${from}: ${reason} nonce=${nonce}`);
  }

  for (; nonce > 0; nonce--) {
    const addr = ethers.utils.getContractAddress({ from, nonce });
    try {
      const code = await provider.getCode(addr);
      if (code.object === "0x") continue;
      const c = new ethers.Contract(addr, erc165Interface, provider);
      // Does it support ERC165, if not it is not the diamond
      if (!(await c.supportsInterface(erc165InterfaceId))) {
        logmiss("not ERC 165", nonce)
        continue
      };
      if (!(await c.supportsInterface(interfaceId))) {
        logmiss(`not ${interfaceId}`, nonce)
        continue;
      }
      return addr;
    } catch (err) {
      logmiss(`error checking code ${err}`, nonce);
    }
  }
  return undefined;
}

main();
