// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/KPXLiquidityPool.sol";
import "../src/KPXFactory.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @dev Minimal ERC-20 for testing
contract MockToken is ERC20 {
    constructor(string memory name, string memory sym) ERC20(name, sym) {
        _mint(msg.sender, 1_000_000e18);
    }
}

contract KPXLiquidityPoolTest is Test {
    MockToken       public tokenA;
    MockToken       public tokenB;
    KPXFactory      public factory;
    KPXLiquidityPool public pool;

    address alice = makeAddr("alice");
    address bob   = makeAddr("bob");

    function setUp() public {
        tokenA  = new MockToken("TokenA", "TKA");
        tokenB  = new MockToken("TokenB", "TKB");
        factory = new KPXFactory(address(this));

        // factory orders canonically — create pool
        address poolAddr = factory.createPool(address(tokenA), address(tokenB));
        pool = KPXLiquidityPool(poolAddr);

        // Fund alice & bob
        tokenA.transfer(alice, 100_000e18);
        tokenB.transfer(alice, 100_000e18);
        tokenA.transfer(bob,   10_000e18);
    }

    // ── Liquidity ─────────────────────────────────────────────────────────────

    function test_addLiquidity_firstDeposit() public {
        vm.startPrank(alice);
        tokenA.approve(address(pool), 10_000e18);
        tokenB.approve(address(pool), 10_000e18);

        (, , uint256 lp) = pool.addLiquidity(10_000e18, 10_000e18, 0, 0, alice);

        assertGt(lp, 0, "LP tokens minted");
        assertEq(pool.reserveA(), 10_000e18);
        assertEq(pool.reserveB(), 10_000e18);
        vm.stopPrank();
    }

    function test_addLiquidity_secondDeposit_maintainsRatio() public {
        // First deposit
        vm.startPrank(alice);
        tokenA.approve(address(pool), 20_000e18);
        tokenB.approve(address(pool), 20_000e18);
        pool.addLiquidity(10_000e18, 10_000e18, 0, 0, alice);

        // Second deposit — same ratio
        (, , uint256 lp2) = pool.addLiquidity(1_000e18, 1_000e18, 900e18, 900e18, alice);
        assertGt(lp2, 0, "second LP minted");
        vm.stopPrank();
    }

    function test_removeLiquidity() public {
        vm.startPrank(alice);
        tokenA.approve(address(pool), 10_000e18);
        tokenB.approve(address(pool), 10_000e18);
        (, , uint256 lp) = pool.addLiquidity(10_000e18, 10_000e18, 0, 0, alice);

        uint256 balBefore = tokenA.balanceOf(alice);
        pool.removeLiquidity(lp, 0, 0, alice);

        assertGt(tokenA.balanceOf(alice), balBefore, "received tokenA back");
        vm.stopPrank();
    }

    // ── Swap ──────────────────────────────────────────────────────────────────

    function test_swapExactIn_aToB() public {
        // Seed pool
        vm.startPrank(alice);
        tokenA.approve(address(pool), 50_000e18);
        tokenB.approve(address(pool), 50_000e18);
        pool.addLiquidity(50_000e18, 50_000e18, 0, 0, alice);
        vm.stopPrank();

        // Bob swaps 1000 A → B
        vm.startPrank(bob);
        address tA = pool.reserveA() == 50_000e18 ? address(tokenA) : address(tokenB);
        tokenA.approve(address(pool), 1_000e18);

        uint256 expectedOut = pool.getAmountOut(1_000e18, tA);
        assertGt(expectedOut, 0, "positive output");
        assertLt(expectedOut, 1_000e18, "output < input (fee applied)");

        uint256 balBefore = tokenB.balanceOf(bob);
        pool.swapExactIn(tA, 1_000e18, expectedOut, bob);
        assertEq(tokenB.balanceOf(bob) - balBefore, expectedOut, "exact output received");
        vm.stopPrank();
    }

    function test_swap_kInvariant() public {
        vm.startPrank(alice);
        tokenA.approve(address(pool), 10_000e18);
        tokenB.approve(address(pool), 10_000e18);
        pool.addLiquidity(10_000e18, 10_000e18, 0, 0, alice);
        uint256 kBefore = pool.reserveA() * pool.reserveB();
        vm.stopPrank();

        vm.startPrank(bob);
        tokenA.approve(address(pool), 500e18);
        address tA = address(tokenA);
        if (address(pool.TOKEN_A()) != address(tokenA)) tA = address(tokenB);
        pool.swapExactIn(tA, 500e18, 0, bob);
        vm.stopPrank();

        uint256 kAfter = pool.reserveA() * pool.reserveB();
        assertGe(kAfter, kBefore, "k must not decrease after swap");
    }

    function test_revert_swapSlippage() public {
        vm.startPrank(alice);
        tokenA.approve(address(pool), 10_000e18);
        tokenB.approve(address(pool), 10_000e18);
        pool.addLiquidity(10_000e18, 10_000e18, 0, 0, alice);
        vm.stopPrank();

        vm.startPrank(bob);
        address tA = address(pool.TOKEN_A());
        tokenA.approve(address(pool), 100e18);
        vm.expectRevert(KPXLiquidityPool.KLP_SlippageExceeded.selector);
        pool.swapExactIn(tA, 100e18, type(uint256).max, bob); // impossible slippage
        vm.stopPrank();
    }

    // ── Factory ───────────────────────────────────────────────────────────────

    function test_factory_createPool_canonical() public {
        MockToken t1 = new MockToken("T1","T1");
        MockToken t2 = new MockToken("T2","T2");

        address p1 = factory.createPool(address(t1), address(t2));
        address p2 = factory.getPool(address(t2), address(t1)); // reversed lookup
        assertEq(p1, p2, "canonical order: both directions resolve");
    }

    function test_factory_revert_duplicate() public {
        vm.expectRevert(KPXFactory.KPX_PoolExists.selector);
        factory.createPool(address(tokenA), address(tokenB));
    }
}
