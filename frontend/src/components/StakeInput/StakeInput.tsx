import React, { useState } from 'react';
import './StakeInput.css';

interface StakeInputProps {
    onStake: (amount: string) => void; // The function to call when stake is to be performed
}

const StakeInput: React.FC<StakeInputProps> = ({ onStake }) => {
    const [amount, setAmount] = useState('');

    const addAmount = (additionalAmount: number) => {
        setAmount((prevAmount) => {
            // Convert to number, add and convert back to string
            return (Number(prevAmount) + additionalAmount).toString();
        });
    };

    return (
        <div className="stake-container">
            <div className="stake-header">
                <p>Stake for rewards, governance, and yield.</p>
            </div>
            <div className="input-group">
                <button onClick={() => setAmount('')}>Clear</button>
                <input
                    type="text"
                    value={amount}
                    onChange={(e) => setAmount(e.target.value)}
                    placeholder="# of LocalTokens"
                />
                <button onClick={() => onStake(amount)}>Stake</button>
            </div>
            <div className="quick-add-buttons">
                <button onClick={() => addAmount(10)}>+10</button>
                <button onClick={() => addAmount(100)}>+100</button>
                <button onClick={() => addAmount(1000)}>+1K</button>
                <button onClick={() => addAmount(10000)}>+10K</button>
                <button onClick={() => addAmount(100000)}>+100K</button>
            </div>
        </div>
    );
};

export default StakeInput;
