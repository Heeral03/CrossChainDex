// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/IntentsManager.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract CoWMatcher is ReentrancyGuard {
    IntentsManager public intents;

    event CoWExecuted(uint256 intentA, uint256 intentB, uint256 clearingPrice);

    constructor(address _intents) {
        intents = IntentsManager(_intents);
    }

    function matchAndExecute(uint256 idA, uint256 idB) external nonReentrant {
        IntentsManager.Intent memory intentA = intents.getIntent(idA);
        IntentsManager.Intent memory intentB = intents.getIntent(idB);

        require(intentA.status == IntentsManager.IntentStatus.Pending, "Intent A not active");
        require(intentB.status == IntentsManager.IntentStatus.Pending, "Intent B not active");

        // Validate tokens are opposite sides of the trade
        require(intentA.tokenIn == intentB.tokenOut, "Token mismatch A->B");
        require(intentA.tokenOut == intentB.tokenIn, "Token mismatch B->A");

        // Simplified price calculation - take the average of both prices
        uint256 priceA = (intentA.minAmountOut * 1e18) / intentA.amountIn;
        uint256 priceB = (intentB.amountIn * 1e18) / intentB.minAmountOut;
        uint256 clearingPrice = (priceA + priceB) / 2;

        // Calculate output amounts
        uint256 amountOutA = (intentA.amountIn * clearingPrice) / 1e18;
        uint256 amountOutB = (intentB.amountIn * 1e18) / clearingPrice;

        // Check slippage against minAmountOut requirements
        require(amountOutA >= intentA.minAmountOut, "A slippage too high");
        require(amountOutB >= intentB.minAmountOut, "B slippage too high");

        // Prepare IERC20 instances for easier reuse
        IERC20 tokenA = IERC20(intentA.tokenIn);
        IERC20 tokenB = IERC20(intentB.tokenIn);

        // Check allowances
        require(tokenA.allowance(intentA.user, address(this)) >= intentA.amountIn, "Insufficient allowance from user A");
        require(tokenB.allowance(intentB.user, address(this)) >= intentB.amountIn, "Insufficient allowance from user B");

        // Check balances
        require(tokenA.balanceOf(intentA.user) >= intentA.amountIn, "Insufficient balance user A");
        require(tokenB.balanceOf(intentB.user) >= intentB.amountIn, "Insufficient balance user B");

        // Execute token transfers atomically
        require(tokenA.transferFrom(intentA.user, intentB.user, intentA.amountIn), "A transferFrom failed");
        require(tokenB.transferFrom(intentB.user, intentA.user, intentB.amountIn), "B transferFrom failed");

        // Mark intents as fulfilled
        intents.markFulfilled(idA);
        intents.markFulfilled(idB);

        emit CoWExecuted(idA, idB, clearingPrice);
    }
}