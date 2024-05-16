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
    globalManagerContractAddress: "0x0DCd1Bf9A1b36cE34237eEaFef220932846BCD82",
  },
  op: {
    name: "Optimism Test Rollup",
    rpcUrl: "http://localhost:8001",
    localTokenContractAddress: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
    stakeContractAddress: "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6",
  },
  arb: {
    name: "Arbitrum Test Rollup",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0xa513E6E4b8f2a923D98304ec87F64353C4D5C853",
    stakeContractAddress: "0x2279B7A0a67DB372996a5FaB50D91eAA73d2eBe6",
  }
};
