import React, { useState } from 'react';
import { ethers } from 'ethers';

const erc20Abi = [
  "function approve(address spender, uint256 amount) public returns (bool)",
  "function allowance(address owner, address spender) public view returns (uint256)",
  "function balanceOf(address owner) public view returns (uint256)"
];

const IntentForm = () => {
  const [sellToken, setSellToken] = useState('');
  const [buyToken, setBuyToken] = useState('');
  const [sellAmount, setSellAmount] = useState('');
  const [minBuyAmount, setMinBuyAmount] = useState('');
  const [sourceChain, setSourceChain] = useState('');
  const [targetChain, setTargetChain] = useState('');
  const [orderType, setOrderType] = useState('Limit Buy');

  const tokenAddresses = {
    Sepolia: {
      USDC: "0x5273cE0CFC959a12EDC5594eFD588034199D4f2D",
      WETH: "0xAa49045062B3216CF5Cf41A36Ec17FdA7Ec61b34",
    }
  };

  const cowMatcherAddress = "0x9ac3750C1A8DeC29Ca9dE7F643583c12Ec33FD5D";

  const handleSubmit = async (e) => {
    e.preventDefault();

    try {
      if (!window.ethereum) {
        alert("Please install MetaMask.");
        return;
      }

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const userAddress = await signer.getAddress();

      const sellTokenAddress = tokenAddresses[sourceChain]?.[sellToken];
      const parsedAmount = ethers.parseUnits(sellAmount.toString(), 18);

      if (!sellTokenAddress) {
        alert("❌ Invalid token or chain");
        return;
      }

      const tokenContract = new ethers.Contract(sellTokenAddress, erc20Abi, signer);

      // 🔍 Check balance
      const balance = await tokenContract.balanceOf(userAddress);
      if (balance < parsedAmount) {
        alert(`❌ Insufficient balance: You only have ${ethers.formatUnits(balance, 18)} ${sellToken}`);
        return;
      }

      // 🔐 Check and approve if needed
      const allowance = await tokenContract.allowance(userAddress, cowMatcherAddress);
      if (allowance < parsedAmount) {
        console.log("🔐 Not enough allowance. Requesting approval...");
        const approvalTx = await tokenContract.approve(cowMatcherAddress, ethers.MaxUint256);
        await approvalTx.wait();
        console.log("✅ Approved with MetaMask:", approvalTx.hash);
      } else {
        console.log("✅ Sufficient allowance already granted");
      }

      // 🚀 Submit intent
      const response = await fetch("http://localhost:3001/api/submit-intent", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          sellToken,
          buyToken,
          sellAmount,
          minBuyAmount,
          chainId: sourceChain === "Sepolia" ? 11155111 : 80001
        }),
      });

      const result = await response.json();
      if (response.ok) {
        alert("✅ Intent submitted! Tx: " + result.txHash);
      } else {
        alert("❌ Failed: " + result.error);
      }
    } catch (err) {
      console.error("🔥 Error:", err);
      alert("Something went wrong: " + err.message);
    }
  };

  return (
    <form onSubmit={handleSubmit} style={formStyle}>
      <Dropdown label="Sell Token" value={sellToken} setValue={setSellToken} options={["USDC", "WETH"]} />
      <Dropdown label="Buy Token" value={buyToken} setValue={setBuyToken} options={["USDC", "WETH"]} />
      <Input label="Sell Amount" value={sellAmount} setValue={setSellAmount} />
      <Input label="Min Buy Amount" value={minBuyAmount} setValue={setMinBuyAmount} />
      <Dropdown label="Source Chain" value={sourceChain} setValue={setSourceChain} options={["Sepolia"]} />
      <Dropdown label="Target Chain" value={targetChain} setValue={setTargetChain} options={["Sepolia"]} />
      <Dropdown label="Order Type" value={orderType} setValue={setOrderType} options={["Limit Buy", "Limit Sell"]} />
      <button type="submit" style={buttonStyle}>Submit Intent</button>
    </form>
  );
};

const Dropdown = ({ label, value, setValue, options }) => (
  <div style={{ marginBottom: '1rem' }}>
    <label>{label}:</label>
    <select value={value} onChange={(e) => setValue(e.target.value)} style={selectStyle}>
      <option value="">Select {label}</option>
      {options.map(opt => <option key={opt} value={opt}>{opt}</option>)}
    </select>
  </div>
);

const Input = ({ label, value, setValue }) => (
  <div style={{ marginBottom: '1rem' }}>
    <label>{label}:</label>
    <input type="number" value={value} onChange={(e) => setValue(e.target.value)} style={inputStyle} />
  </div>
);

const formStyle = {
  backgroundColor: '#000',
  color: '#fff',
  maxWidth: '500px',
  margin: '0 auto',
  border: '2px solid #00ff00',
  padding: '0.8rem',
  borderRadius: '8px'
};

const selectStyle = {
  width: '100%',
  padding: '0.4rem',
  borderRadius: '4px',
  backgroundColor: '#fff',
  color: '#000'
};

const inputStyle = {
  width: '100%',
  padding: '0.4rem',
  borderRadius: '4px',
  backgroundColor: '#fff',
  color: '#000'
};

const buttonStyle = {
  width: '100%',
  borderRadius: '4px',
  backgroundColor: 'green',
  color: '#fff',
  fontWeight: 'bold',
  border: 'none',
  cursor: 'pointer'
};

export default IntentForm;
