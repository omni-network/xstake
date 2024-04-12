import React from 'react';
import './LoadingModal.css';

interface LoadingModalProps {
    isOpen: boolean;
    status: string;
}

const LoadingModal: React.FC<LoadingModalProps> = ({ isOpen, status }) => {
    if (!isOpen) return null;

    return (
        <div className="modal-overlay">
            <div className="modal-content">
                <img src="./favicon.svg" className={`spinner ${status === 'complete' && 'completed'}`} alt="logo-spinner" />
                <p>{status === 'loading' ? 'Transaction is being processed...' : 'Transaction complete!'}</p>
            </div>
        </div>
    );
};

export default LoadingModal;
