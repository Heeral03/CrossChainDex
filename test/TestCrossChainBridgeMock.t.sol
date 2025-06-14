// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/CrossChainBridgeMock.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CrossChainBridgeMockTest is Test {
    CrossChainBridgeMock bridge;
    ERC20Mock token;
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    uint256 chainId = 1;
    uint256 targetChainId = 42161; // Arbitrum chain ID example

    function setUp() public {
        bridge = new CrossChainBridgeMock();
        token = new ERC20Mock("Test Token", "TEST");

        // Mint tokens to user1 for testing
        token.mint(user1, 1000 ether);

        // User1 approves bridge to spend tokens
        vm.prank(user1);
        token.approve(address(bridge), type(uint256).max);
    }

    function test_BridgeOut() public {
        uint256 bridgeAmount = 100 ether;
        uint256 initialBalance = token.balanceOf(user1);

        // Expect BridgedOut event
        vm.expectEmit(true, true, false, true);
        emit CrossChainBridgeMock.BridgedOut(user1, address(token), bridgeAmount, targetChainId);

        // Perform bridge out
        vm.prank(user1);
        bridge.bridgeOut(address(token), bridgeAmount, targetChainId);

        // Verify user's token balance was deducted
        assertEq(token.balanceOf(user1), initialBalance - bridgeAmount, "Token balance not deducted");
    }

    function test_BridgeOutRevertsIfAmountZero() public {
        vm.prank(user1);
        vm.expectRevert("Amount must be > 0");
        bridge.bridgeOut(address(token), 0, targetChainId);
    }

    function test_BridgeIn() public {
        uint256 bridgeAmount = 100 ether;

        // Expect BridgedIn event
        vm.expectEmit(true, true, false, true);
        emit CrossChainBridgeMock.BridgedIn(user1, address(token), bridgeAmount, chainId);

        // Perform bridge in (normally called by bridge relayer)
        bridge.bridgeIn(user1, address(token), bridgeAmount, chainId);

        // Verify mock balance was updated
        assertEq(bridge.userBalances(user1, address(token)), bridgeAmount, "Bridge balance not updated");
    }

    function test_BridgeInRevertsIfAmountZero() public {
        vm.expectRevert("Amount must be > 0");
        bridge.bridgeIn(user1, address(token), 0, chainId);
    }

    function test_UserBalancesMapping() public {
        uint256 bridgeAmount = 50 ether;

        // Bridge in some tokens
        bridge.bridgeIn(user1, address(token), bridgeAmount, chainId);
        bridge.bridgeIn(user2, address(token), bridgeAmount * 2, chainId);

        // Verify balances
        assertEq(bridge.userBalances(user1, address(token)), bridgeAmount, "User1 balance incorrect");
        assertEq(bridge.userBalances(user2, address(token)), bridgeAmount * 2, "User2 balance incorrect");
    }

    function testFuzz_BridgeIn(uint256 amount) public {
        vm.assume(amount > 0 && amount < type(uint128).max); // Avoid overflow

        bridge.bridgeIn(user1, address(token), amount, chainId);
        assertEq(bridge.userBalances(user1, address(token)), amount, "Fuzz: balance mismatch");
    }
}
