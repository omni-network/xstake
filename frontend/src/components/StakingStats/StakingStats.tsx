import React from 'react';

interface StakingStatsProps {
    userTotalStakedLocal: string;
    totalStakedLocal: string;
    totalStakedOnOmni: string;
}

const StakingStats: React.FC<StakingStatsProps> = ({
    userTotalStakedLocal,
    totalStakedLocal,
    totalStakedOnOmni
}) => {
    return (
        <div className="stats-container">
            <div className="user-stats">
                <p>{userTotalStakedLocal}</p>
                <p>Staked in total by you on this network</p>
            </div>
            <div className="network-stats">
                <p>{totalStakedLocal}</p>
                <p>Staked in total on this network</p>
            </div>
            <div className="global-stats">
                <p>{totalStakedOnOmni}</p>
                <p>Staked in total on all networks</p>
            </div>
        </div>
    );
};

export default StakingStats;
