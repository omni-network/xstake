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
    globalManagerContractAddress: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  },
  op: {
    name: "Optimism Test Rollup",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    stakeContractAddress: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  },
  arb: {
    name: "Arbitrum Test Rollup",
    rpcUrl: "http://localhost:8003",
    localTokenContractAddress: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
    stakeContractAddress: "0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9",
  }
};
