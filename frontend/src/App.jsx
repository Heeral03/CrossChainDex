import React from "react";
import IntentForm from "./components/IntentForm";
import WalletConnect from "./components/WalletConnect";
import "./App.css"
const App = () => {
  return (
    <div>
      <WalletConnect />
      <IntentForm />
    </div>
  );
};

export default App;
