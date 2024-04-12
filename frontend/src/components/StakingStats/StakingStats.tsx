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
        return (value / 1000).toFixed(value % 1000 === 0 ? 0 : 1) + 'K'; // Round to nearest thousand with one decimal place if needed
    } else if (value >= 1000000 && value < 1000000000) {
        return (value / 1000000).toFixed(value % 1000000 === 0 ? 0 : 1) + 'M'; // Round to nearest million with one decimal place if needed
    } else if (value >= 1000000000) {
        return (value / 1000000000).toFixed(value % 1000000000 === 0 ? 0 : 1) + 'B'; // Round to nearest billion with one decimal place if needed
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
