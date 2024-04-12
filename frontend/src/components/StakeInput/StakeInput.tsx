import React, { useState } from 'react';
import './StakeInput.css';

interface StakeInputProps {
    onStake: (amount: string) => void; // The function to call when stake is to be performed
}

const StakeInput: React.FC<StakeInputProps> = ({ onStake }) => {
    const [amount, setAmount] = useState('');

    const addAmount = (additionalAmount: number) => {
        setAmount((prevAmount) => {
            // Remove spaces, convert to number, add, and convert back to string with spaces as separators
            const cleanAmount = prevAmount.replace(/\s/g, '');
            const newAmount = Number(cleanAmount) + additionalAmount;
            return formatNumber(newAmount);
        });
    };

    const formatNumber = (number: string | number | bigint) => {
        return new Intl.NumberFormat('fr-FR').format(Number(number));
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const inputNumber = e.target.value.replace(/\s/g, ''); // Remove spaces for calculation
        if (/^\d*$/.test(inputNumber)) { // Allow only numeric input
            setAmount(formatNumber(inputNumber));
        }
    };

    const handleStake = () => {
        // Remove spaces before passing the value to onStake
        onStake(amount.replace(/\s/g, ''));
    };

    return (
        <div className="stake-container">
            <div className="stake-header">
                <p>Stake for rewards, governance, and yield.</p>
            </div>
            <div className="stake-input">
                <div className="input-group">
                    <button onClick={() => setAmount('')}>Clear</button>
                    <input
                        type="text"
                        value={amount}
                        onChange={handleInputChange}
                        placeholder="# LocalTokens"
                    />
                    <button onClick={handleStake}>Stake</button>
                </div>
                <div className="quick-add-buttons">
                    <button onClick={() => addAmount(10)}>+10</button>
                    <button onClick={() => addAmount(100)}>+100</button>
                    <button onClick={() => addAmount(1000)}>+1K</button>
                    <button onClick={() => addAmount(10000)}>+10K</button>
                    <button onClick={() => addAmount(100000)}>+100K</button>
                </div>
            </div>
        </div>
    );
};

export default StakeInput;
