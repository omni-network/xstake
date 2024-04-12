import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import localStakeAbi from './abis/LocalStake.json';
import globalManagerAbi from './abis/GlobalManager.json';
import localTokenAbi from './abis/LocalToken.json';
import { networks } from './constants/networks';

import Navbar from './components/Navbar/Navbar';
import StakeInput from './components/StakeInput/StakeInput';
import StakingStats from './components/StakingStats/StakingStats';

import './App.css';


function App() {
  const [stakeVal, setStakeVal] = useState(0); // Store the amount to stake
  const [currentAccount, setCurrentAccount] = useState(''); // Store the current connected account
  const [currentNetwork, setCurrentNetwork] = useState('op'); // Default network is OP
  const [totalStakedOnOmni, setTotalStakedOnOmni] = useState(''); // Store the total staked globally
  const [totalStakedLocal, setTotalStakedLocal] = useState(''); // Store the total staked on the current network
  const [userTotalStakedLocal, setUserTotalStakedLocal] = useState(''); // Store the total staked by the user on the current network

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
      const chainId = await getNetworkChainId(network);
      (window as any).ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
          chainId: ethers.toBeHex(chainId),
          rpcUrls: [networks[network].rpcUrl],
          chainName: networks[network].name,
          nativeCurrency: {
            name: "ETH",
            symbol: "ETH",
            decimals: 18
          },
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
      const stakeContract = getStakeContract(signer);
      const stakeAddress = await stakeContract.getAddress();
      const localTokenContract = getLocalTokenContract(signer);

      // Calculate the amount for ERC20 tokens to stake
      const tokenAmount = ethers.parseEther(amount);
      // Check if the user has approved the stake contract to spend the tokens
      const allowance = await localTokenContract.allowance(currentAccount, stakeAddress);
      console.log("Allowance:", allowance.toString());
      if (allowance < tokenAmount) {
        console.log("Approving stake contract to spend tokens");
        const totalSupply = await localTokenContract.totalSupply();
        const aTx = await localTokenContract.approve(stakeAddress, ethers.parseEther(totalSupply.toString()));
        await aTx.wait();
        const newAllowance = await localTokenContract.allowance(currentAccount, stakeAddress);
        console.log("New allowance:", newAllowance.toString());
      }

      // This value should be adjusted based on the actual xcall fee requirement
      const xcallFee = ethers.parseEther("0.01");

      const sTx = await stakeContract.stake(tokenAmount, { value: xcallFee });
      await sTx.wait();
      alert(`Staked successfully on ${currentNetwork}`);
      setStakeVal(stakeVal + parseInt(amount));
    } catch (error) {
      console.error("Failed to stake:", (error as any).message);
    }
  };

  const getTotalStaked = async () => {
    try {
      const provider = new ethers.JsonRpcProvider(networks['omni'].rpcUrl);
      const globalManagerContract = getGlobalManagerContract(provider);

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
      const localTokenContract = getLocalTokenContract(provider);

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
      const globalManagerContract = getGlobalManagerContract(omniProvider);
      const chainId = await getNetworkChainId(currentNetwork);

      const userTotalStaked = await globalManagerContract.getUserStakeOnChain(currentAccount, chainId);
      setUserTotalStakedLocal(ethers.formatEther(userTotalStaked));
    } catch (error) {
      console.error("Failed to fetch user local staked:", (error as any).message);
    }
  }

  useEffect(() => {
    getTotalStakedLocal();
    if (!currentAccount) {
      return;
    }
    getUserTotalStakedLocal();
  }, [currentAccount, currentNetwork]);

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

      <Navbar
        currentNetwork={currentNetwork}
        networks={networks}
        requestNetworkChange={requestNetworkChange}
        currentAccount={currentAccount}
        connectWallet={connectWallet}
      />

      <StakeInput onStake={stake} />

      <StakingStats
            userTotalStakedLocal={userTotalStakedLocal}
            totalStakedLocal={totalStakedLocal}
            totalStakedOnOmni={totalStakedOnOmni}
        />
    </div>
  );

  async function getNetworkChainId(network: string) {
    const provider = new ethers.JsonRpcProvider(networks[network].rpcUrl);
    const chainId = (await provider.getNetwork()).chainId;
    return chainId;
  }

  function getGlobalManagerContract(provider: ethers.JsonRpcProvider) {
    const globalManagerAddress = networks.omni.globalManagerContractAddress;
    if (!globalManagerAddress) {
      throw new Error('Global manager contract address not found for Omni network');
    }
    const globalManagerContract = new ethers.Contract(globalManagerAddress, globalManagerAbi, provider);
    return globalManagerContract;
  }

  function getStakeContract(signer: ethers.JsonRpcSigner) {
    const stakeAddress = networks[currentNetwork].stakeContractAddress;
    if (!stakeAddress) {
      throw new Error(`Stake contract address not found for network: ${currentNetwork}`);
    }
    const stakeContract = new ethers.Contract(stakeAddress, localStakeAbi, signer);
    return stakeContract;
  }

  function getLocalTokenContract(signer: ethers.JsonRpcSigner | ethers.JsonRpcProvider) {
    const localTokenAddress = networks[currentNetwork].localTokenContractAddress;
    if (!localTokenAddress) {
      throw new Error(`Local token contract address not found for network: ${currentNetwork}`);
    }
    const localTokenContract = new ethers.Contract(localTokenAddress, localTokenAbi, signer);
    return localTokenContract;
  }
}

export default App;