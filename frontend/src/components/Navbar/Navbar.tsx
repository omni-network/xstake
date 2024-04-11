// Navbar.tsx
import React from 'react';

import './Navbar.css';

interface NavbarProps {
  currentNetwork: string;
  networks: { [key: string]: any }; // Adjust the type based on your networks structure
  requestNetworkChange: (network: string) => void;
  currentAccount: string;
  connectWallet: () => void;
}

const Navbar: React.FC<NavbarProps> = ({
  currentNetwork,
  networks,
  requestNetworkChange,
  currentAccount,
  connectWallet
}) => {

  const handleNetworkChange = () => {
    const otherNetwork = currentNetwork === 'op' ? 'arb' : 'op';
    requestNetworkChange(otherNetwork);
  };

  return (
    <nav className="navbar">
      <img src={`${process.env.PUBLIC_URL}/logo.svg`} alt="Logo" className="logo" />
      <div className="navbar-right">
        <div className="network-selector">
          {networks[currentNetwork].name}
        </div>
        <button className="change-network" onClick={handleNetworkChange}>Change Network</button>
        <button className="connect-wallet" onClick={connectWallet}>
          {currentAccount ? `${currentAccount.substring(0, 6)}...${currentAccount.substring(currentAccount.length - 4)}` : 'Connect Wallet'}
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
