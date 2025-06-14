// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";
import "../src/IntentsManager.sol";

contract TestIntentsManager is Test {
    IntentsManager intents;

    // Users
    address constant ALICE = address(0xABCD);
    address constant BOB   = address(0xBEEF);

    // Tokens
    address constant TOKEN_IN  = address(0x1111);
    address constant TOKEN_OUT = address(0x2222);

    // Values
    uint256 constant AMOUNT_IN = 100e18;
    uint256 constant MIN_AMOUNT_OUT = 50e18;
    uint256 constant CHAIN_ID = 137;

    function setUp() public {
        intents = new IntentsManager();
    }

    function testSubmitIntentStoresCorrectData() public {
        vm.prank(ALICE);
        uint256 id = intents.submitIntent(TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);

        IntentsManager.Intent memory i = intents.getIntent(id);
        assertEq(i.user, ALICE);
        assertEq(i.tokenIn, TOKEN_IN);
        assertEq(i.tokenOut, TOKEN_OUT);
        assertEq(i.amountIn, AMOUNT_IN);
        assertEq(i.minAmountOut, MIN_AMOUNT_OUT);
        assertEq(i.chainId, CHAIN_ID);
        assertEq(uint(i.status), uint(IntentsManager.IntentStatus.Pending));
    }

    function testEmitIntentSubmittedEvent() public {
        vm.prank(ALICE);
        vm.expectEmit(true, true, true, true);
        emit IntentsManager.IntentSubmitted(0, ALICE, TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);

        intents.submitIntent(TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);
    }

    function testUpdateIntentStatusToMatched() public {
        vm.prank(ALICE);
        uint256 id = intents.submitIntent(TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);

        vm.expectEmit(true, false, false, true);
        emit IntentsManager.IntentStatusUpdated(id, IntentsManager.IntentStatus.Matched);
        intents.updateIntentStatus(id, IntentsManager.IntentStatus.Matched);

        IntentsManager.Intent memory i = intents.getIntent(id);
        assertEq(uint(i.status), uint(IntentsManager.IntentStatus.Matched));
    }

    function testMarkFulfilledChangesStatus() public {
        vm.prank(ALICE);
        uint256 id = intents.submitIntent(TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);

        vm.expectEmit(true, false, false, true);
        emit IntentsManager.IntentStatusUpdated(id, IntentsManager.IntentStatus.Fulfilled);

        intents.markFulfilled(id);
        assertEq(uint(intents.getIntent(id).status), uint(IntentsManager.IntentStatus.Fulfilled));
    }

    function testGetIntentRevertsOnInvalidId() public {
        vm.expectRevert("Intent does not exist");
        intents.getIntent(99);
    }

    function testIsPendingTrueFalseLogic() public {
        vm.prank(ALICE);
        uint256 id = intents.submitIntent(TOKEN_IN, TOKEN_OUT, AMOUNT_IN, MIN_AMOUNT_OUT, CHAIN_ID);

        assertTrue(intents.isPending(id));
        intents.updateIntentStatus(id, IntentsManager.IntentStatus.Cancelled);
        assertFalse(intents.isPending(id));
    }

    function testUpdateIntentStatusRevertsForInvalidId() public {
        vm.expectRevert("Invalid intent ID");
        intents.updateIntentStatus(100, IntentsManager.IntentStatus.Fulfilled);
    }
}
