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
    stakeContractAddress: "0x9E545E3C0baAB3E08CdfD552C960A1050f373042",
    localTokenContractAddress: "0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB",
  },
  arb: {
    name: "Arbitrum",
    rpcUrl: "http://localhost:8003",
    stakeContractAddress: "0x322813Fd9A801c5507c9de605d63CEA4f2CE6c44",
    localTokenContractAddress: "0x4ed7c70F96B99c776995fB64377f0d4aB3B0e1C1",
  },
  omni: {
    name: "Omni",
    rpcUrl: "http://localhost:8000",
    globalManagerContractAddress: "0xc6e7DF5E7b4f2A278906862b61205850344D4e7d",
  }
};
