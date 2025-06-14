// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "../src/IntentsManager.sol";
import {console} from "../lib/forge-std/src/console.sol";

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract CFMMAdapter {
    address public immutable router;

    constructor(address _router) {
        router = _router;
    }

    struct SwapParams {
        address user;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
    }

    function swapViaAMM(SwapParams memory params) external returns (bool) {
        address[] memory path = new address[](2);
        path[0] = params.tokenIn;
        path[1] = params.tokenOut;

        // Check allowance first
        require(
            IERC20(params.tokenIn).allowance(params.user, address(this)) >= params.amountIn,
            "Insufficient allowance"
        );

        // Transfer tokens from user (only once)
        require(
            IERC20(params.tokenIn).transferFrom(
                params.user,
                address(this),
                params.amountIn
            ),
            "TransferFrom failed"
        );
        
        // Approve router (using standard approve)
        require(
            IERC20(params.tokenIn).approve(router, params.amountIn),
            "Approve failed"
        );

        try IUniswapV2Router(router).swapExactTokensForTokens(
            params.amountIn,
            params.minAmountOut,
            path,
            params.user, // Send directly to user
            block.timestamp + 300
        ) returns (uint[] memory amounts) {
            require(amounts[1] >= params.minAmountOut, "Insufficient output");
            return true;
        } catch {
            // Return tokens to user if swap fails
            IERC20(params.tokenIn).transfer(params.user, params.amountIn);
            return false;
        }
    }
}