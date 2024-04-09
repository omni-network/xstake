import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import localStakeAbi from './abis/LocalStake.json';
import globalManagerAbi from './abis/GlobalManager.json';
import localTokenAbi from './abis/LocalToken.json';
import { networks } from './constants/networks';

function App() {
  const [currentNetwork, setCurrentNetwork] = useState('op'); // Default network
  const [totalStakedOnOmni, setTotalStakedOnOmni] = useState('');
  const [currentAccount, setCurrentAccount] = useState(''); // Store the current connected account

  // Connect to the user's wallet
  const connectWallet = async () => {
    try {
      // Check if MetaMask is installed
      if ((window as any).ethereum) {
        const accounts = await (window as any).ethereum.request({ method: 'eth_requestAccounts' });
        if (accounts.length === 0) {
          console.log('No account found');
        } else {
          console.log('Connected account:', accounts[0]);
          setCurrentAccount(accounts[0]); // Set the first account as the current account
        }
      } else {
        alert('MetaMask is not installed. Please install it to use this app.');
      }
    } catch (error) {
      console.error(error);
    }
  };

  // Modified getProvider function to use MetaMask's provider if an account is connected
  const getProvider = () => {
    if (!currentAccount) {
      // Fallback to JsonRpcProvider if no account is connected
      return new ethers.JsonRpcProvider(networks[currentNetwork].rpcUrl);
    }
    // Use BrowserProvider for connected accounts
    return new ethers.BrowserProvider((window as any).ethereum);
  };

  const stake = async (amount: string) => {
    if (!currentAccount) {
      alert("Please connect your wallet first.");
      return;
    }

    const provider = getProvider();
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
    try {
      const provider = new ethers.JsonRpcProvider(networks['omni'].rpcUrl);
      const globalManagerAddress = networks.omni.globalManagerContractAddress;
      if (!globalManagerAddress) {
        throw new Error('Global manager contract address not found for Omni network');
      }
      const globalManagerContract = new ethers.Contract(globalManagerAddress, globalManagerAbi, provider);
    
      const totalStaked = await globalManagerContract.getTotalStake();
      setTotalStakedOnOmni(ethers.formatEther(totalStaked));
    } catch (error) {
      console.error("Failed to fetch total staked:", (error as any).message);
    }
  };

  useEffect(() => {
    // Only fetch total staked if a current account is set
    getTotalStaked();
  }, [currentAccount]); // Re-run this effect when currentAccount changes

  return (
    <div>
      <h2>Current Network: {networks[currentNetwork].name}</h2>
      <div>
        <button onClick={() => setCurrentNetwork('op')}>Switch to OP Network</button>
        <button onClick={() => setCurrentNetwork('arb')}>Switch to ARB Network</button>
      </div>
      <div>
        {currentAccount ? (
          <p>Connected as: {currentAccount}</p>
        ) : (
          <button onClick={connectWallet}>Connect Wallet</button>
        )}
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
