// IntentForm.jsx
import React, { useState } from 'react';

const IntentForm = () => {
  const [sellToken, setSellToken] = useState('');
  const [buyToken, setBuyToken] = useState('');
  const [sellAmount, setSellAmount] = useState('');
  const [minBuyAmount, setMinBuyAmount] = useState('');
  const [sourceChain, setSourceChain] = useState('');
  const [targetChain, setTargetChain] = useState('');
  const [orderType, setOrderType] = useState('Limit Buy');

  const handleSubmit = (e) => {
    e.preventDefault();
    // Placeholder submit logic
    console.log('Form submitted with values:', {
      sellToken,
      buyToken,
      sellAmount,
      minBuyAmount,
      sourceChain,
      targetChain,
      orderType
    });
  };

  return (
    <form
      onSubmit={handleSubmit}
      style={{
        backgroundColor: '#000000',
        color: '#fff',
        maxWidth: '500px',
        margin: '0 auto',

        border: '2px solid #00ff00',
        padding: '0.8rem',
        borderRadius: '8px'
      }}
    >
      <div style={{ marginBottom: '0.5rem' }}>
        <label>Sell Token:</label>
        <select
          value={sellToken}
          onChange={(e) => setSellToken(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        >
          <option value="">Select Token</option>
          <option value="USDC">USDC</option>
          <option value="LINK">LINK</option>
          <option value="ETH">ETH</option>
        </select>
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Buy Token:</label>
        <select
          value={buyToken}
          onChange={(e) => setBuyToken(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        >
          <option value="">Select Token</option>
          <option value="USDC">USDC</option>
          <option value="LINK">LINK</option>
          <option value="ETH">ETH</option>
        </select>
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Sell Amount:</label>
        <input
          type="number"
          value={sellAmount}
          onChange={(e) => setSellAmount(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        />
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Min Buy Amount:</label>
        <input
          type="number"
          value={minBuyAmount}
          onChange={(e) => setMinBuyAmount(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        />
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Source Chain:</label>
        <select
          value={sourceChain}
          onChange={(e) => setSourceChain(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        >
          <option value="">Select Chain</option>
          <option value="Ethereum">Ethereum</option>
          <option value="Sepolia">Sepolia</option>
          <option value="BNC Testnet">BNC Testnet</option>
          <option value="Polygon">Polygon</option>
        </select>
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Target Chain:</label>
        <select
          value={targetChain}
          onChange={(e) => setTargetChain(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        >
          <option value="">Select Chain</option>
          <option value="Solana">Solana</option>
          <option value="Sepolia">Sepolia</option>
          <option value="Sepolia">BNC Testnet</option>
          <option value="Avalanche">Avalanche</option>
        </select>
      </div>

      <div style={{ marginBottom: '1rem' }}>
        <label>Order Type:</label>
        <select
          value={orderType}
          onChange={(e) => setOrderType(e.target.value)}
          style={{ width: '100%', padding: '0.4rem', borderRadius: '4px', backgroundColor: '#fff', color: '#000' }}
        >
          <option value="Limit Buy">Limit Buy</option>
          <option value="Limit Sell">Limit Sell</option>
        </select>
      </div>

      <button
        type="submit"
        style={{
          width: '100%',
          
          borderRadius: '4px',
          backgroundColor: 'green',
          color: '#fff',
          fontWeight: 'bold',
          border: 'none',
          cursor: 'pointer'
        }}
      >
        Submit Intent
      </button>
    </form>
  );
};

export default IntentForm;
