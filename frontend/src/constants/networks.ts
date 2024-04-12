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
    rpcUrl: "http://localhost:8001",
    globalManagerContractAddress: "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318",
  },
  op: {
    name: "Optimism Test Rollup",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82",
    stakeContractAddress: "0x9A676e781A523b5d0C0e43731313A708CB607508",
  },
  arb: {
    name: "Arbitrum Test Rollup",
    rpcUrl: "http://localhost:8003",
    localTokenContractAddress: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    stakeContractAddress: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  }
};
