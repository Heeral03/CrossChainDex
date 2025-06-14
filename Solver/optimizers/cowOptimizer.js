function matchCoWs(intents) {
  const matches = [];

  for (let i = 0; i < intents.length; i++) {
    for (let j = i + 1; j < intents.length; j++) {
      const a = intents[i];
      const b = intents[j];

if (
  a.sellToken === b.buyToken &&
  a.buyToken === b.sellToken &&
  Number(a.sellAmount) >= Number(b.minBuyAmount) &&
  Number(b.sellAmount) >= Number(a.minBuyAmount)
)
 {
        matches.push({ a, b });
      }
    }
  }

  console.log("🔎 Matches found:", matches.length);
  return matches;
}

module.exports = matchCoWs;
