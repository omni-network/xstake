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
  op: {
    name: "Optimism",
    rpcUrl: "http://localhost:8002",
    stakeContractAddress: "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c",
    localTokenContractAddress: "0x68B1D87F95878fE05B998F19b66F4baba5De1aed",
  },
  arb: {
    name: "Arbitrum",
    rpcUrl: "http://localhost:8003",
    stakeContractAddress: "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c",
    localTokenContractAddress: "0x68B1D87F95878fE05B998F19b66F4baba5De1aed",
  },
  omni: {
    name: "Omni",
    rpcUrl: "http://localhost:8000",
    globalManagerContractAddress: "0x3Aa5ebB10DC797CAC828524e59A333d0A371443c",
  }
};
