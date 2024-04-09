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
    name: "Omni",
    rpcUrl: "http://localhost:8000",
    globalManagerContractAddress: "0xb7278A61aa25c888815aFC32Ad3cC52fF24fE575",
  },
  op: {
    name: "Optimism",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0x4C2F7092C2aE51D986bEFEe378e50BD4dB99C901",
    stakeContractAddress: "0x7A9Ec1d04904907De0ED7b6839CcdD59c3716AC9",
  },
  arb: {
    name: "Arbitrum",
    rpcUrl: "http://localhost:8003",
    localTokenContractAddress: "0x4c5859f0F772848b2D91F1D83E2Fe57935348029",
    stakeContractAddress: "0x1291Be112d480055DaFd8a610b7d1e203891C274",
  }
};
