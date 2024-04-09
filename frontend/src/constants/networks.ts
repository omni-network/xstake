// src/constants/networks.ts
interface Network {
  name: string;
  rpcUrl: string;
  stakeContractAddress?: string;
  localTokenContractAddress?: string;
  globalManagerContractAddress?: string;
}

interface Networks {
  [key: string]: Network;
}

export const networks: Networks = {
  omni: {
    name: "Omni Test",
    rpcUrl: "http://localhost:8000",
    globalManagerContractAddress: "0xc351628EB244ec633d5f21fBD6621e1a683B1181",
  },
  op: {
    name: "Optimism Test Rollup",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0xCace1b78160AE76398F486c8a18044da0d66d86D",
    stakeContractAddress: "0xD5ac451B0c50B9476107823Af206eD814a2e2580",
  },
  arb: {
    name: "Arbitrum Test Rollup",
    rpcUrl: "http://localhost:8003",
    localTokenContractAddress: "0x5081a39b8A5f0E35a8D959395a630b68B74Dd30f",
    stakeContractAddress: "0x1fA02b2d6A771842690194Cf62D91bdd92BfE28d",
  }
};
