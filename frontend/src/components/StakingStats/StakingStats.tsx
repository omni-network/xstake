import React from 'react';

import './StakingStats.css';

interface StakingStatsProps {
    userTotalStakedLocal: string;
    totalStakedLocal: string;
    totalStakedOnOmni: string;
}

function formatNumber(numberString: string): string {
    const value = parseFloat(numberString); // Convert string to number
    if (value >= 1000 && value < 1000000) {
        const formattedValue = (value / 1000).toFixed(value % 1000 === 0 ? 0 : 1); // Round to nearest thousand with one decimal place if needed
        return formattedValue.replace('.0', '') + 'K'; // Remove ".0" if present and append 'K'
    } else if (value >= 1000000 && value < 1000000000) {
        const formattedValue = (value / 1000000).toFixed(value % 1000000 === 0 ? 0 : 1); // Round to nearest million with one decimal place if needed
        return formattedValue.replace('.0', '') + 'M'; // Remove ".0" if present and append 'M'
    } else if (value >= 1000000000) {
        const formattedValue = (value / 1000000000).toFixed(value % 1000000000 === 0 ? 0 : 1); // Round to nearest billion with one decimal place if needed
        return formattedValue.replace('.0', '') + 'B'; // Remove ".0" if present and append 'B'
    }
    return value.toString(); // Directly return the value if less than 1000
}

const StakingStats: React.FC<StakingStatsProps> = ({
    userTotalStakedLocal,
    totalStakedLocal,
    totalStakedOnOmni
}) => {
    return (
        <div className="stats-container">
            <div className="user-stats">
                <h3>{formatNumber(userTotalStakedLocal)}</h3>
                <p>Your total stake on this network</p>
            </div>
            <div className="network-stats">
                <h3>{formatNumber(totalStakedLocal)}</h3>
                <p>Total Staked on this network</p>
            </div>
            <div className="global-stats">
                <h3>{formatNumber(totalStakedOnOmni)}</h3>
                <p>Total staked on all networks</p>
            </div>
        </div>
    );
};

export default StakingStats;
