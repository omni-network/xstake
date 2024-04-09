import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import localStakeAbi from './abis/LocalStake.json';
import globalManagerAbi from './abis/GlobalManager.json';
import localTokenAbi from './abis/LocalToken.json';
import { networks } from './constants/networks';

function App() {
  const [stakeVal, setStakeVal] = useState(0); // Store the amount to stake
  const [currentAccount, setCurrentAccount] = useState(''); // Store the current connected account
  const [currentNetwork, setCurrentNetwork] = useState('op'); // Default network is OP
  const [totalStakedOnOmni, setTotalStakedOnOmni] = useState(''); // Store the total staked globally
  const [totalStakedLocal, setTotalStakedLocal] = useState(''); // Store the total staked on the current network
  const [userTotalStakedLocal, setUserTotalStakedLocal] = useState('?'); // Store the total staked by the user on the current network

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

  // Request to switch the network
  const requestNetworkChange = async (network: string) => {
    try {
      const provider = new ethers.JsonRpcProvider(networks[network].rpcUrl);
      const chainId = (await provider.getNetwork()).chainId;
      if (!chainId) {
        throw new Error(`Chain ID not found for network: ${network}`);
      }
      const chainIdHex = ethers.toBeHex(chainId);
      const rpcUrl = networks[network].rpcUrl;
      (window as any).ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
            chainId: chainIdHex,
            rpcUrls: [rpcUrl],
            chainName: networks[network].name,
            nativeCurrency: {
                name: "ETH",
                symbol: "ETH",
                decimals: 18
            },
            blockExplorerUrls: ["https://etherscan.io"]
        }]
    });
      setCurrentNetwork(network);
    } catch (error) {
      console.error(error);
    }
  };

  const stake = async (amount: string) => {
    try {
      if (!currentAccount) {
        alert("Please connect your wallet first.");
        return;
      }

      const provider = new ethers.BrowserProvider((window as any).ethereum);
      const signer = await provider.getSigner(currentAccount);
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
      // Check if the user has approved the stake contract to spend the tokens
      const allowance = await localTokenContract.allowance(currentAccount, stakeAddress);
      console.log("Allowance:", allowance.toString());
      if (allowance < tokenAmount) {
        await localTokenContract.approve(stakeAddress, await localTokenContract.totalSupply());
      }

      // This value should be adjusted based on the actual xcall fee requirement
      const xcallFee = ethers.parseEther("0.01");

      const tx = await stakeContract.stake(tokenAmount, { value: xcallFee });
      await tx.wait();
      alert(`Staked successfully on ${currentNetwork}`);
      setStakeVal(stakeVal + parseInt(amount));
    } catch (error) {
      console.error("Failed to stake:", (error as any).message);
    }
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

  const getTotalStakedLocal = async () => {
    try {
      const provider = new ethers.JsonRpcProvider(networks[currentNetwork].rpcUrl);
      const stakeAddress = networks[currentNetwork].stakeContractAddress;
      const localTokenAddress = networks[currentNetwork].localTokenContractAddress;
      if (!localTokenAddress) {
        throw new Error(`Local token contract address not found for network: ${currentNetwork}`);
      }
      const localTokenContract = new ethers.Contract(localTokenAddress, localTokenAbi, provider);

      const totalStaked = await localTokenContract.balanceOf(stakeAddress);
      setTotalStakedLocal(ethers.formatEther(totalStaked));
    } catch (error) {
      console.error("Failed to fetch local staked:", (error as any).message);
    }
  };

  const getUserTotalStakedLocal = async () => {
    try {
      if (!currentAccount) {
        console.error("No account found");
        return;
      }

      const omniProvider = new ethers.JsonRpcProvider(networks['omni'].rpcUrl);
      const globalManagerAddress = networks.omni.globalManagerContractAddress;
      if (!globalManagerAddress) {
        throw new Error('Global manager contract address not found for Omni network');
      }
      const globalManagerContract = new ethers.Contract(globalManagerAddress, globalManagerAbi, omniProvider);
      const provider = new ethers.JsonRpcProvider(networks[currentNetwork].rpcUrl);
      const chainId = (await provider.getNetwork()).chainId;

      const userTotalStaked = await globalManagerContract.getUserStakeOnChain(currentAccount, chainId);
      setUserTotalStakedLocal(ethers.formatEther(userTotalStaked));
    } catch (error) {
      console.error("Failed to fetch user local staked:", (error as any).message);
    }
  }

  useEffect(() => {
    if (!currentAccount) {
      return;
    }
    getUserTotalStakedLocal();
  }, [currentAccount, currentNetwork]); 

  useEffect(() => {
    getTotalStakedLocal();
    if (!currentAccount) {
      return;
    }
    getUserTotalStakedLocal();
  }, [currentNetwork]);

  useEffect(() => {
    getTotalStakedLocal();
    getTotalStaked();
    if (!currentAccount) {
      return;
    }
    getUserTotalStakedLocal();
  }, [stakeVal]);

  useEffect(() => {
    getTotalStakedLocal();
    getTotalStaked();
    if (!currentAccount) {
      return;
    }
    getUserTotalStakedLocal();
  }, []);

  return (
    <div>
      <h2>Current Network: {networks[currentNetwork].name}</h2>
      <div>
        <button onClick={() => requestNetworkChange('op')}>Switch to OP Network</button>
        <button onClick={() => requestNetworkChange('arb')}>Switch to ARB Network</button>
      </div>
      <br/>
      <div>
        {currentAccount ? (
          <p>Connected as: {currentAccount}</p>
        ) : (
          <button onClick={connectWallet}>Connect Wallet</button>
        )}
      </div>
      <br/>
      <div>
        <input type="text" placeholder="# of LocalTokens" id="stakeAmount" />
        <button onClick={() => stake((document.getElementById('stakeAmount') as HTMLInputElement)?.value)}>Stake</button>
        <h3>User Info</h3>
        <p>Staked on this Network: {userTotalStakedLocal} LocalTokens</p>
        <h3>App Info</h3>
        <p>Staked on this Network: {totalStakedLocal} LocalTokens</p>
        <p>Staked Globally: {totalStakedOnOmni} LocalTokens</p>
      </div>
    </div>
  );
}

export default App;
