
import { createPublicClient, http } from "viem";
import { getBytecode } from "viem/actions";
import { saga } from "wagmi/chains";

const wethbranch = {
  collToken: "0xeb41D53F14Cb9a67907f2b8b5DBc223944158cCb",
  addressesRegistry: "0x8b5869e67351df545612b65d9141f1e8370e94e2",
  activePool: "0x79971d6cc9a8c70784d4d7930a19a33b5d0ef51c",
  borrowerOperations: "0x9e54923469fbadde2eae63fea2a13bdc1e9b97ef",
  collSurplusPool: "0x89b0ce41fa9178c2abf677518af006748966b396",
  defaultPool: "0x928eafb5fe8649d5576aafc25a975e1e42bc469d",
  sortedTroves: "0xeae0ee6b833ff6d8500d92703dbdf1b3bf9fea3f",
  stabilityPool: "0x736c85cb1e30ebdbc25bce1204d1118d3b0b9db6",
  troveManager: "0xad29692f867d167840689308b84b991df8b72891",
  troveNFT: "0xe694323a46892683a3fb169a6d83de7bf572f665",
  metadataNFT: "0x08543452d773879bd5f6bb4df938c2ce322affa3",
  priceFeed: "0x74356978abc3b22ad2318f6ad507891b40fa1ad4",
  gasPool: "0x0c8a1b0f8e3d6f745ca9cf01720e48ae3011b758",
  leverageZapper: "0x4F026FaC6747CC7f4C33f0691900088D3028f6D0",
};

async function checkAddresses() {
  for (const [key, address] of Object.entries(wethbranch)) {
    try {
      const client  = createPublicClient({
        chain: saga,
        transport: http()
      })
      const bytecode = await getBytecode(client, {
        address: address as `0x${string}`,
        blockNumber: 5375346n,
        
      });
      if (bytecode && bytecode !== "0x") {
        console.log(`${key}: ${address} HAS bytecode`);
      } else {
        console.log(`${key}: ${address} has NO bytecode`);
      }
    } catch (err) {
      console.error(`${key}: ${address} failed to fetch bytecode`, err);
    }
  }
}

checkAddresses();