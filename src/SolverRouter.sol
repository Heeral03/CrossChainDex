// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IntentsManager } from "./IntentsManager.sol";
import { CoWMatcher } from "./CoWMatcher.sol";
import { CFMMAdapter } from "./CFMMAdapter.sol";

contract SolverRouter {
    CoWMatcher public cowMatcher;
    CFMMAdapter public cfmmAdapter;
    IntentsManager public intentsManager;

    event TradeExecuted(uint256 indexed intentId, uint256 indexed matchedIntentId);

    constructor(address _cowMatcher, address _cfmmAdapter, address _intentsManager) {
        cowMatcher = CoWMatcher(_cowMatcher);
        cfmmAdapter = CFMMAdapter(_cfmmAdapter);
        intentsManager = IntentsManager(_intentsManager);
    }

    function solve(uint256 intentId, uint256 matchedIntentId) external {
        require(intentsManager.isPending(intentId), "Intent not pending");
        require(intentsManager.isPending(matchedIntentId), "Matched intent not pending");

        // Directly call matchAndExecute, no canMatch check
        cowMatcher.matchAndExecute(intentId, matchedIntentId);

        // If above reverts, fallback not reached. If success, mark fulfilled below.
        intentsManager.markFulfilled(intentId);
        intentsManager.markFulfilled(matchedIntentId);

        emit TradeExecuted(intentId, matchedIntentId);
    }
}
