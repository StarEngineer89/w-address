import { MerkleTree } from "merkletreejs";
// import config from "./address.json" with { type: "json" };
import whitelist from "./whitelist.json" with { type: "json" };
import { keccak256 }  from "ethers";
function main() {    
    let leaves = whitelist.map((x) => keccak256(x));    
    const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
    const root = merkleTree.getHexRoot();
    console.log("Root:", root);
}

main();