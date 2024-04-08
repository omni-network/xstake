import React from 'react';
import { createRoot } from 'react-dom/client'; // Import createRoot
import App from './App';
// import './index.css';

const container = document.getElementById('root');
if (container) { // Check if container is not null
  const root = createRoot(container); // Create a root.
  root.render(
    <React.StrictMode>
      <App />
    </React.StrictMode>
  );
}
