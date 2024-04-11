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
    globalManagerContractAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  },
  op: {
    name: "Optimism Test Rollup",
    rpcUrl: "http://localhost:8002",
    localTokenContractAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    stakeContractAddress: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  },
  arb: {
    name: "Arbitrum Test Rollup",
    rpcUrl: "http://localhost:8003",
    localTokenContractAddress: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
    stakeContractAddress: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
  }
};
