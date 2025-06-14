// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../lib/forge-std/src/Test.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/SolverRouter.sol";
import "../src/IntentsManager.sol";
import "../src/CoWMatcher.sol";
import "../src/CFMMAdapter.sol";

contract ERC20Mock is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract SolverRouterTest is Test {
    // Addresses
    address ALICE;
    address BOB;
    address UNISWAP_ROUTER;

    ERC20Mock tokenA;
    ERC20Mock tokenB;

    SolverRouter public solverRouter;
    IntentsManager public intentsManager;
    CoWMatcher public cowMatcher;
    CFMMAdapter public cfmmAdapter;

    uint256 public intentIdA;
    uint256 public intentIdB;

    event TradeExecuted(uint256 indexed intentId, uint256 indexed matchedIntentId);

    function setUp() public {
        ALICE = makeAddr("ALICE");
        BOB = makeAddr("BOB");
        UNISWAP_ROUTER = makeAddr("UNISWAP_ROUTER");

        // Deploy mock ERC20 tokens
        tokenA = new ERC20Mock("TokenA", "TKA");
        tokenB = new ERC20Mock("TokenB", "TKB");

        // Mint tokens to ALICE and BOB
        tokenA.mint(ALICE, 1_000 ether);
        tokenB.mint(BOB, 1_000 ether);

        // Deploy main contracts
        intentsManager = new IntentsManager();
        cowMatcher = new CoWMatcher(address(intentsManager));
        cfmmAdapter = new CFMMAdapter(UNISWAP_ROUTER);
        solverRouter = new SolverRouter(
            address(cowMatcher),
            address(cfmmAdapter),
            address(intentsManager)
        );

        // ALICE approves CoWMatcher to spend her tokenA
        vm.prank(ALICE);
        tokenA.approve(address(cowMatcher), type(uint256).max);

        // BOB approves CoWMatcher to spend his tokenB
        vm.prank(BOB);
        tokenB.approve(address(cowMatcher), type(uint256).max);

        // ALICE submits intent (100 TOKEN_A for at least 95 TOKEN_B)
        vm.prank(ALICE);
        intentIdA = intentsManager.submitIntent(
            address(tokenA),
            address(tokenB),
            100 ether,
            95 ether,
            block.chainid
        );

        // BOB submits matching intent (95 TOKEN_B for at least 100 TOKEN_A)
        vm.prank(BOB);
        intentIdB = intentsManager.submitIntent(
            address(tokenB),
            address(tokenA),
            95 ether,
            100 ether,
            block.chainid
        );
    }

    function testSolveSuccessful() public {
        vm.expectEmit(true, true, true, true);
        emit TradeExecuted(intentIdA, intentIdB);

        solverRouter.solve(intentIdA, intentIdB);

        IntentsManager.Intent memory a = intentsManager.getIntent(intentIdA);
        IntentsManager.Intent memory b = intentsManager.getIntent(intentIdB);

        assertEq(uint8(a.status), uint8(IntentsManager.IntentStatus.Fulfilled));
        assertEq(uint8(b.status), uint8(IntentsManager.IntentStatus.Fulfilled));
    }

    function testRevertIfIntentNotPending() public {
        vm.prank(address(this));
        intentsManager.updateIntentStatus(intentIdA, IntentsManager.IntentStatus.Fulfilled);

        vm.expectRevert("Intent not pending");
        solverRouter.solve(intentIdA, intentIdB);
    }

    function testRevertIfMatchedIntentNotPending() public {
        vm.prank(address(this));
        intentsManager.updateIntentStatus(intentIdB, IntentsManager.IntentStatus.Fulfilled);

        vm.expectRevert("Matched intent not pending");
        solverRouter.solve(intentIdA, intentIdB);
    }
}
