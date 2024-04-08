// src/constants/networks.ts
interface Network {
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
    rpcUrl: "http://localhost:8002",
    stakeContractAddress: "OP_STAKE_CONTRACT_ADDRESS",
    localTokenContractAddress: "OP_LOCAL_TOKEN_CONTRACT_ADDRESS",
  },
  arb: {
    rpcUrl: "http://localhost:8003",
    stakeContractAddress: "ARB_STAKE_CONTRACT_ADDRESS",
    localTokenContractAddress: "ARB_LOCAL_TOKEN_CONTRACT_ADDRESS",
  },
  omni: {
    rpcUrl: "http://localhost:8000",
    globalManagerContractAddress: "GLOBAL_MANAGER_CONTRACT_ADDRESS",
  }
};
