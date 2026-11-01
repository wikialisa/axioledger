// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — KPX Pool Factory
// kinetoprotocol ($KPX)
//
// Deploys and tracks KPXLiquidityPool instances.
// Each (tokenA, tokenB) pair → exactly one pool (canonical order enforced).
//
pragma solidity ^0.8.28;

import "./KPXLiquidityPool.sol";

/// @title KPXFactory — deploys and indexes KPX liquidity pools
contract KPXFactory {

    // pool[tokenA][tokenB] — tokenA < tokenB always
    mapping(address => mapping(address => address)) public getPool;
    address[] public allPools;

    address public feeTo;    // protocol fee recipient
    address public feeToSetter;

    event PoolCreated(address indexed tokenA, address indexed tokenB, address pool, uint256 poolCount);

    error KPX_IdenticalTokens();
    error KPX_ZeroAddress();
    error KPX_PoolExists();
    error KPX_Forbidden();

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    /// @notice Deploy a new pool for (tokenA, tokenB). Pair order is canonicalised.
    function createPool(address tokenA, address tokenB) external returns (address pool) {
        if (tokenA == tokenB)       revert KPX_IdenticalTokens();
        if (tokenA == address(0))   revert KPX_ZeroAddress();

        // canonical order
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);

        if (getPool[tokenA][tokenB] != address(0)) revert KPX_PoolExists();

        pool = address(new KPXLiquidityPool(tokenA, tokenB, address(this), feeTo));

        getPool[tokenA][tokenB] = pool;
        getPool[tokenB][tokenA] = pool; // both directions resolve
        allPools.push(pool);

        emit PoolCreated(tokenA, tokenB, pool, allPools.length);
    }

    function setFeeTo(address _feeTo) external {
        if (msg.sender != feeToSetter) revert KPX_Forbidden();
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        if (msg.sender != feeToSetter) revert KPX_Forbidden();
        feeToSetter = _feeToSetter;
    }
}
