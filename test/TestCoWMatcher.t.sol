// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/forge-std/src/Test.sol";

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "../src/IntentsManager.sol";
import "../src/CoWMatcher.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract CoWMatcherTest is Test {
    address ALICE;
    address BOB;

    ERC20Mock tokenA;
    ERC20Mock tokenB;

    IntentsManager intentsManager;
    CoWMatcher cowMatcher;

    uint256 intentIdA;
    uint256 intentIdB;

    event CoWExecuted(uint256 indexed intentA, uint256 indexed intentB, uint256 clearingPrice);

    function setUp() public {
        ALICE = makeAddr("ALICE");
        BOB = makeAddr("BOB");

        // Deploy mock tokens
        tokenA = new ERC20Mock("TokenA", "TKA");
        tokenB = new ERC20Mock("TokenB", "TKB");

        // Mint tokens
        tokenA.mint(ALICE, 1_000 ether);
        tokenB.mint(BOB, 1_000 ether);

        // Deploy IntentsManager and CoWMatcher
        intentsManager = new IntentsManager();
        cowMatcher = new CoWMatcher(address(intentsManager));

        // ALICE approves CoWMatcher to spend tokenA
        vm.prank(ALICE);
        tokenA.approve(address(cowMatcher), type(uint256).max);

        // BOB approves CoWMatcher to spend tokenB
        vm.prank(BOB);
        tokenB.approve(address(cowMatcher), type(uint256).max);

        // ALICE submits intent: sell 100 tokenA for min 95 tokenB
        vm.prank(ALICE);
        intentIdA = intentsManager.submitIntent(
            address(tokenA),
            address(tokenB),
            100 ether,
            95 ether,
            block.chainid
        );

        // BOB submits intent: sell 95 tokenB for min 100 tokenA
        vm.prank(BOB);
        intentIdB = intentsManager.submitIntent(
            address(tokenB),
            address(tokenA),
            95 ether,
            100 ether,
            block.chainid
        );
    }

function testMatchAndExecuteSuccessful() public {
    // Record logs before the first execution
    vm.recordLogs();
    
    // Execute the match
    cowMatcher.matchAndExecute(intentIdA, intentIdB);
    
    // Get the recorded logs
    Vm.Log[] memory entries = vm.getRecordedLogs();

    // Check intent statuses
    IntentsManager.Intent memory intentA = intentsManager.getIntent(intentIdA);
    IntentsManager.Intent memory intentB = intentsManager.getIntent(intentIdB);

    assertEq(uint8(intentA.status), uint8(IntentsManager.IntentStatus.Fulfilled));
    assertEq(uint8(intentB.status), uint8(IntentsManager.IntentStatus.Fulfilled));

    // Decode and inspect the emitted event
    // We need to find the CoWExecuted event in the logs
    bytes memory emittedEvent;
    for (uint256 i = 0; i < entries.length; i++) {
        if (entries[i].topics[0] == keccak256("CoWExecuted(uint256,uint256,uint256)")) {
            emittedEvent = entries[i].data;
            break;
        }
    }
    
    require(emittedEvent.length > 0, "CoWExecuted event not found");
    
    (uint256 emittedIntentA, uint256 emittedIntentB, uint256 emittedPrice) = abi.decode(
        emittedEvent,
        (uint256, uint256, uint256)
    );

    console.log("Emitted intentA:", emittedIntentA);
    console.log("Emitted intentB:", emittedIntentB);
    console.log("Emitted price:", emittedPrice);

    // Verify the values
    assertEq(emittedIntentA, intentIdA);
    assertEq(emittedIntentB, intentIdB);
    
    // Calculate expected clearing price
    uint256 priceA = (95 ether * 1e18) / 100 ether; // 0.95 ether (95e17)
    uint256 priceB = (95 ether * 1e18) / 100 ether; // 0.95 ether (95e17)
    uint256 expectedClearingPrice = (priceA + priceB) / 2; // Should be 95e17
    
    assertEq(emittedPrice, expectedClearingPrice);
}


    function test_RevertIfIntentANotPending() public {
        // Mark intentA as fulfilled manually
        vm.prank(address(this));
        intentsManager.updateIntentStatus(intentIdA, IntentsManager.IntentStatus.Fulfilled);

        vm.expectRevert("Intent A not active");
        cowMatcher.matchAndExecute(intentIdA, intentIdB);
    }

    function test_RevertIfIntentBNotPending() public {
        // Mark intentB as fulfilled manually
        vm.prank(address(this));
        intentsManager.updateIntentStatus(intentIdB, IntentsManager.IntentStatus.Fulfilled);

        vm.expectRevert("Intent B not active");
        cowMatcher.matchAndExecute(intentIdA, intentIdB);
    }

    function test_RevertIfTokensMismatch() public {
        // Submit intent with mismatched tokens (same tokenIn and tokenOut)
        vm.prank(ALICE);
        uint256 badIntentId = intentsManager.submitIntent(
            address(tokenA),
            address(tokenA),
            10 ether,
            9 ether,
            block.chainid
        );

        // The error message depends on CoWMatcher's internal check:
        // It can be "Token mismatch A->B" or "Token mismatch B->A".
        // Adjust accordingly. Here, we assume it throws "Token mismatch B->A"
        vm.expectRevert("Token mismatch B->A");
        cowMatcher.matchAndExecute(badIntentId, intentIdB);
    }

    function test_RevertIfSlippageTooHigh() public {
        // Submit intent with too high minAmountOut to trigger slippage revert
        vm.prank(ALICE);
        uint256 intentHighSlippage = intentsManager.submitIntent(
            address(tokenA),
            address(tokenB),
            100 ether,
            150 ether,
            block.chainid
        );

        vm.expectRevert("A slippage too high");
        cowMatcher.matchAndExecute(intentHighSlippage, intentIdB);
    }
}
