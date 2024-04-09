import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import localStakeAbi from './abis/LocalStake.json';
import globalManagerAbi from './abis/GlobalManager.json';
import localTokenAbi from './abis/LocalToken.json';
import { networks } from './constants/networks';

function App() {
  const [currentNetwork, setCurrentNetwork] = useState('op'); // Default network
  const [totalStakedOnOmni, setTotalStakedOnOmni] = useState('');

  const getProvider = (networkKey: string) => new ethers.JsonRpcProvider(networks[networkKey].rpcUrl);

  const stake = async (amount: string) => {
    const provider = getProvider(currentNetwork);
    const signer = await provider.getSigner();
    const stakeAddress = networks[currentNetwork].stakeContractAddress;
    if (!stakeAddress) {
      throw new Error(`Stake contract address not found for network: ${currentNetwork}`);
    }
    const stakeContract = new ethers.Contract(stakeAddress, localStakeAbi, signer);
    const localTokenAddress = networks[currentNetwork].localTokenContractAddress;
    if (!localTokenAddress) {
      throw new Error(`Local token contract address not found for network: ${currentNetwork}`);
    }
    const localTokenContract = new ethers.Contract(localTokenAddress, localTokenAbi, signer);

    // Calculate the amount for ERC20 tokens to stake
    const tokenAmount = ethers.parseEther(amount);
    await localTokenContract.approve(stakeAddress, tokenAmount);

    // This value should be adjusted based on the actual xcall fee requirement
    const xcallFee = ethers.parseEther("0.01");

    const tx = await stakeContract.stake(tokenAmount, { value: xcallFee });
    await tx.wait();
    alert(`Staked successfully on ${currentNetwork}`);
    getTotalStaked(); // Update total staked on successful stake
  };

  const getTotalStaked = async () => {
    const provider = getProvider('omni');
    const globalManagerAddress = networks.omni.globalManagerContractAddress;
    if (!globalManagerAddress) {
      throw new Error('Global manager contract address not found for Omni network');
    }
    const globalManagerContract = new ethers.Contract(globalManagerAddress, globalManagerAbi, provider);

    const totalStaked = await globalManagerContract.getTotalStake();
    setTotalStakedOnOmni(ethers.formatEther(totalStaked));
  };

  // Fetch total staked on Omni when the component mounts
  useEffect(() => {
    getTotalStaked();
  }, []); // The empty dependency array makes this effect run only on mount

  return (
    <div>
      <h2>Current Network: {networks[currentNetwork].name}</h2>
      <div>
        <button onClick={() => setCurrentNetwork('op')}>Switch to OP Network</button>
        <button onClick={() => setCurrentNetwork('arb')}>Switch to ARB Network</button>
      </div>
      <div>
        <input type="text" placeholder="# of LocalTokens" id="stakeAmount" />
        <button onClick={() => stake((document.getElementById('stakeAmount') as HTMLInputElement)?.value)}>Stake</button>
      </div>
      <div>
        <p>Total Staked on Omni: {totalStakedOnOmni} LocalTokens</p>
      </div>
    </div>
  );
}

export default App;
