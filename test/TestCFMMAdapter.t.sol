// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/IntentsManager.sol";
import "../src/CFMMAdapter.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract MockRouter {
    event SwapExecuted(
        uint amountIn,
        uint amountOut,
        address tokenIn,
        address tokenOut,
        address to
    );

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "Invalid path");
        require(deadline >= block.timestamp, "Deadline passed");
        
        // Transfer input tokens from caller (adapter)
        require(
            IERC20(path[0]).transferFrom(
                msg.sender,
                address(this),
                amountIn
            ),
            "TransferFrom failed"
        );

        // Transfer output tokens
        require(
            IERC20(path[1]).transfer(to, amountOutMin),
            "Output transfer failed"
        );

        emit SwapExecuted(
            amountIn,
            amountOutMin,
            path[0],
            path[1],
            to
        );

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountOutMin;
        return amounts;
    }
}

contract CFMMAdapterTest is Test {
    address USER;
    ERC20Mock tokenA;
    ERC20Mock tokenB;
    CFMMAdapter adapter;
    MockRouter mockRouter;

    function setUp() public {
        USER = makeAddr("USER");

        tokenA = new ERC20Mock("Token A", "TKA");
        tokenB = new ERC20Mock("Token B", "TKB");

        // Mint tokens
        tokenA.mint(USER, 1000 ether);
        tokenB.mint(address(this), 1000 ether);

        mockRouter = new MockRouter();
        adapter = new CFMMAdapter(address(mockRouter));

        // Fund the router with TokenB
        tokenB.mint(address(mockRouter), 1000 ether);

        // Approvals
        vm.prank(USER);
        tokenA.approve(address(adapter), type(uint256).max);
    }

    function testSwapViaAMM() public {
        console.log("Starting testSwapViaAMM");
        
        CFMMAdapter.SwapParams memory params = CFMMAdapter.SwapParams({
            user: USER,
            tokenIn: address(tokenA),
            tokenOut: address(tokenB),
            amountIn: 100 ether,
            minAmountOut: 90 ether
        });

        console.log("Initial TokenA balance:", tokenA.balanceOf(USER));
        console.log("Initial TokenB balance:", tokenB.balanceOf(USER));
        console.log("Router TokenB balance:", tokenB.balanceOf(address(mockRouter)));

        vm.prank(USER);
        bool success = adapter.swapViaAMM(params);
        
        console.log("Swap result:", success);
        console.log("Final TokenA balance:", tokenA.balanceOf(USER));
        console.log("Final TokenB balance:", tokenB.balanceOf(USER));
        console.log("Adapter TokenA balance:", tokenA.balanceOf(address(adapter)));
        console.log("Router TokenB balance:", tokenB.balanceOf(address(mockRouter)));

        assertTrue(success, "Swap should succeed");
        assertEq(tokenA.balanceOf(USER), 900 ether, "TokenA balance incorrect");
        assertEq(tokenB.balanceOf(USER), 90 ether, "TokenB balance incorrect");
    }
}