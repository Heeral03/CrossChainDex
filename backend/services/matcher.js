const { ethers } = require("ethers");
const config = require("../config");
const { logMatch } = require("../matches");

const provider = new ethers.JsonRpcProvider(config.rpc.sepolia);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const solverRouter = new ethers.Contract(
  config.contracts.solverRouter,
  config.abis.solverRouter,
  signer
);

// ✅ Compatibility logic
function areCompatible(a, b) {
  return (
    a.sellToken === b.buyToken &&
    a.buyToken === b.sellToken &&
    a.sellAmount === b.minBuyAmount &&
    a.minBuyAmount === b.sellAmount &&
    a.chainId === b.chainId &&
    a.status === 0 &&
    b.status === 0
  );
}

// ✅ Single matcher
function findMatchForIntent(newIntent, existingIntents) {
  for (let i = 0; i < existingIntents.length; i++) {
    const existing = existingIntents[i];
    if (areCompatible(newIntent, existing)) {
      return { a: newIntent, b: existing };
    }
  }
  return null;
}

// ✅ Bulk matcher
function getAllMatches(intents) {
  const matches = [];
  const used = new Set();

  for (let i = 0; i < intents.length; i++) {
    for (let j = i + 1; j < intents.length; j++) {
      const a = intents[i];
      const b = intents[j];

      if (used.has(i) || used.has(j)) continue;

      if (areCompatible(a, b)) {
        matches.push({ a, b });
        used.add(i);
        used.add(j);
        break;
      }
    }
  }

  return matches;
}

// ✅ Executable solver

async function matchIntentsIfCompatible({ a, b }) {
  if (a.status !== 0 || b.status !== 0) return;
  if (!areCompatible(a, b)) return;

  try {
    const tx = await solverRouter.solve(a.intentId, b.intentId);
    console.log(`⚡ Matching ${a.intentId} ↔ ${b.intentId} | Tx: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`✅ Match executed in block ${receipt.blockNumber}`);
    logMatch(a, b, tx.hash);

    return {
      success: true,
      txHash: tx.hash,
    };
  } catch (err) {
    if (
      err.code === 'CALL_EXCEPTION' &&
      err.reason === "Matched intent not pending"
    ) {
      // 🔕 This is expected sometimes due to concurrency — skip silently
    } else {
      console.error(`❌ Failed to solve ${a.intentId} ↔ ${b.intentId}:`, err.message);
    }
    return { success: false };
  }
}


// ✅ Exports
module.exports = {
  findMatchForIntent,
  getAllMatches,
  matchIntentsIfCompatible,
};
