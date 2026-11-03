// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../interfaces/IKPXDarkPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Mock Dark Pool — kiểm soát threshold và simulate swap
contract MockDarkPool is IKPXDarkPool {
    uint256 public threshold = 100_000 * 1e18; // 100K tokens
    bool    public shouldReenter = false;       // Flag để test reentrancy
    address public routerAddress;

    // Reentrancy attack callback
    bytes   private _reentrantCalldata;

    function setThreshold(uint256 _t)      external { threshold = _t; }
    function setShouldReenter(bool _r, address _router, bytes calldata _cd) external {
        shouldReenter = _r;
        routerAddress = _router;
        _reentrantCalldata = _cd;
    }

    function getInstitutionalThreshold() external view override returns (uint256) {
        return threshold;
    }

    function executeConfidentialSwap(
        address sender,
        uint256 amountIn,
        address[] calldata path,
        bytes calldata
    ) external override returns (uint256 amountOut) {
        // Mô phỏng 1:1 swap để test đơn giản
        amountOut = amountIn;

        // ⚠️ REENTRANCY ATTACK SIMULATION
        // Nếu shouldReenter = true, gọi lại router trong khi đang trong call stack
        if (shouldReenter && routerAddress != address(0)) {
            // Attempt reentrant call vào KPXRouterGateway
            (bool success, bytes memory data) = routerAddress.call(_reentrantCalldata);
            // Test expect: call này phải REVERT do ReentrancyGuard
            // Nếu không revert → ReentrancyGuard bị bypass → BUG NGHIÊM TRỌNG
            require(!success, string(abi.encodePacked("REENTRANCY_NOT_BLOCKED: ", data)));
        }

        // Transfer token out (simulate)
        if (path.length >= 2) {
            IERC20 tokenOut = IERC20(path[path.length - 1]);
            if (tokenOut.balanceOf(address(this)) >= amountOut) {
                tokenOut.transfer(sender, amountOut);
            }
        }
    }

    function placeSealedOrder(bytes32, uint256) external payable override returns (bytes32) {
        return keccak256(abi.encodePacked(msg.sender, block.number));
    }

    function isOrderActive(bytes32) external pure override returns (bool) {
        return true;
    }
}
