const fetchIntents = require('../intents/fetchIntents');
const matchCoWs = require('../optimizers/cowOptimizer');
const submitMatch = require('../services/submitMatch');

async function runSolver() {
  const intents = await fetchIntents();
  console.log("📦 Intents fetched:", intents);

  const matches = matchCoWs(intents);

  for (const match of matches) {
    await submitMatch(match);
  }
}

runSolver();
