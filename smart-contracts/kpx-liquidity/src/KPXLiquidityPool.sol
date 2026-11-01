// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — KPX Liquidity Pool (AMM Core)
// kinetoprotocol ($KPX)
//
// Constant-product AMM: x * y = k
// Supports:
//   - addLiquidity / removeLiquidity
//   - swap (tokenA ↔ tokenB)
//   - LP token minting (ERC-20)
//   - 0.3% swap fee → LP providers
//
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title KPXLiquidityPool — Constant-Product AMM Pool
/// @notice Uniswap v2-inspired AMM pool for KPX DEX.
///         LP tokens represent proportional share of the pool.
contract KPXLiquidityPool is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // ── Constants ────────────────────────────────────────────────────────────

    uint256 public constant FEE_NUMERATOR   = 997;   // 0.3% fee
    uint256 public constant FEE_DENOMINATOR = 1000;
    uint256 public constant MINIMUM_LIQUIDITY = 1000; // locked forever (anti-inflation)

    // ── State ────────────────────────────────────────────────────────────────

    IERC20 public immutable TOKEN_A;
    IERC20 public immutable TOKEN_B;

    uint256 public reserveA;
    uint256 public reserveB;

    address public factory;
    address public feeRecipient; // protocol fee destination (KPX treasury)
    uint16  public protocolFeeBps; // basis points taken from swap fee, default 0

    // ── Events ───────────────────────────────────────────────────────────────

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swap(address indexed sender, address tokenIn, uint256 amountIn, uint256 amountOut, address indexed to);
    event ReservesUpdated(uint256 reserveA, uint256 reserveB);

    // ── Errors ───────────────────────────────────────────────────────────────

    error KLP_InsufficientLiquidity();
    error KLP_InsufficientInputAmount();
    error KLP_InsufficientOutputAmount();
    error KLP_InvalidToken();
    error KLP_SlippageExceeded();
    error KLP_ZeroAmount();
    error KLP_K(); // k invariant violated

    // ── Constructor ──────────────────────────────────────────────────────────

    constructor(
        address _tokenA,
        address _tokenB,
        address _factory,
        address _feeRecipient
    ) ERC20("KPX-LP", "KPX-LP") {
        require(_tokenA != address(0) && _tokenB != address(0), "zero address");
        require(_tokenA != _tokenB, "identical tokens");

        // Canonical ordering (lower address = token A)
        if (_tokenA > _tokenB) (_tokenA, _tokenB) = (_tokenB, _tokenA);

        TOKEN_A       = IERC20(_tokenA);
        TOKEN_B       = IERC20(_tokenB);
        factory       = _factory;
        feeRecipient  = _feeRecipient;
    }

    // ── Liquidity ────────────────────────────────────────────────────────────

    /// @notice Add liquidity. First provider sets the price ratio.
    /// @param amountADesired   Max TOKEN_A to deposit
    /// @param amountBDesired   Max TOKEN_B to deposit
    /// @param amountAMin       Min TOKEN_A accepted (slippage guard)
    /// @param amountBMin       Min TOKEN_B accepted (slippage guard)
    /// @param to               LP token recipient
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external nonReentrant returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        if (amountADesired == 0 || amountBDesired == 0) revert KLP_ZeroAmount();

        (uint256 rA, uint256 rB) = (reserveA, reserveB);

        if (rA == 0 && rB == 0) {
            // First deposit — set initial price
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // Maintain ratio
            uint256 amountBOptimal = (amountADesired * rB) / rA;
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert KLP_SlippageExceeded();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = (amountBDesired * rA) / rB;
                if (amountAOptimal < amountAMin) revert KLP_SlippageExceeded();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }

        TOKEN_A.safeTransferFrom(msg.sender, address(this), amountA);
        TOKEN_B.safeTransferFrom(msg.sender, address(this), amountB);

        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {
            liquidity = _sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
            _mint(address(0xdead), MINIMUM_LIQUIDITY); // lock minimum forever
        } else {
            liquidity = _min(
                (amountA * totalSupply_) / rA,
                (amountB * totalSupply_) / rB
            );
        }

        if (liquidity == 0) revert KLP_InsufficientLiquidity();
        _mint(to, liquidity);

        _updateReserves(rA + amountA, rB + amountB);
        emit LiquidityAdded(to, amountA, amountB, liquidity);
    }

    /// @notice Remove liquidity by burning LP tokens.
    function removeLiquidity(
        uint256 lpAmount,
        uint256 amountAMin,
        uint256 amountBMin,
        address to
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        if (lpAmount == 0) revert KLP_ZeroAmount();

        uint256 totalSupply_ = totalSupply();
        amountA = (lpAmount * reserveA) / totalSupply_;
        amountB = (lpAmount * reserveB) / totalSupply_;

        if (amountA < amountAMin || amountB < amountBMin) revert KLP_SlippageExceeded();
        if (amountA == 0 || amountB == 0) revert KLP_InsufficientLiquidity();

        _burn(msg.sender, lpAmount);
        TOKEN_A.safeTransfer(to, amountA);
        TOKEN_B.safeTransfer(to, amountB);

        _updateReserves(reserveA - amountA, reserveB - amountB);
        emit LiquidityRemoved(to, amountA, amountB, lpAmount);
    }

    // ── Swap ─────────────────────────────────────────────────────────────────

    /// @notice Swap exact `amountIn` of `tokenIn` for at least `amountOutMin` of the other token.
    function swapExactIn(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    ) external nonReentrant returns (uint256 amountOut) {
        if (amountIn == 0) revert KLP_InsufficientInputAmount();

        bool aToB = tokenIn == address(TOKEN_A);
        if (!aToB && tokenIn != address(TOKEN_B)) revert KLP_InvalidToken();

        (uint256 rIn, uint256 rOut) = aToB ? (reserveA, reserveB) : (reserveB, reserveA);

        amountOut = _getAmountOut(amountIn, rIn, rOut);
        if (amountOut < amountOutMin) revert KLP_SlippageExceeded();
        if (amountOut == 0) revert KLP_InsufficientOutputAmount();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        (aToB ? TOKEN_B : TOKEN_A).safeTransfer(to, amountOut);

        uint256 newRA = aToB ? rIn + amountIn : rIn - amountOut;
        uint256 newRB = aToB ? rOut - amountOut : rOut + amountIn;
        if (aToB) {
            _updateReserves(newRA, newRB);
        } else {
            _updateReserves(newRB, newRA);
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut, to);
    }

    // ── Price oracle (spot) ───────────────────────────────────────────────────

    /// @notice Spot price of TOKEN_A in units of TOKEN_B (18-decimal fixed-point).
    function priceAInB() external view returns (uint256) {
        if (reserveA == 0) return 0;
        return (reserveB * 1e18) / reserveA;
    }

    /// @notice Calculate output for a given input using constant-product formula with fee.
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        bool aToB = tokenIn == address(TOKEN_A);
        (uint256 rIn, uint256 rOut) = aToB ? (reserveA, reserveB) : (reserveB, reserveA);
        return _getAmountOut(amountIn, rIn, rOut);
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _getAmountOut(uint256 amountIn, uint256 rIn, uint256 rOut)
        internal pure returns (uint256)
    {
        if (rIn == 0 || rOut == 0) revert KLP_InsufficientLiquidity();
        uint256 amountInWithFee = amountIn * FEE_NUMERATOR;
        return (amountInWithFee * rOut) / (rIn * FEE_DENOMINATOR + amountInWithFee);
    }

    function _updateReserves(uint256 _rA, uint256 _rB) internal {
        reserveA = _rA;
        reserveB = _rB;
        emit ReservesUpdated(_rA, _rB);
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) { y = z; z = (x / z + z) / 2; }
        return y;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
