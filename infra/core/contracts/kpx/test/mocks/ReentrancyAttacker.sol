// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Kẻ tấn công Reentrancy — mô phỏng tấn công thực tế
/// @dev Hợp đồng này cố gắng gọi lại KPXRouterGateway trong fallback/receive
///      để kiểm tra ReentrancyGuard hoạt động đúng
contract ReentrancyAttacker {
    address public target;          // KPXRouterGateway
    address public token;           // Token đang attack
    uint256 public attackCount;     // Số lần reenter đã thực hiện
    bool    public attackTriggered; // Flag: tấn công đã được kích hoạt
    bytes   private _attackCalldata; // Calldata để gọi lại

    event AttackAttempted(uint256 count, bool success);
    event AttackFailed(string reason);

    constructor(address _target, address _token) {
        target = _target;
        token  = _token;
    }

    /// @notice Setup calldata cho reentrancy attack
    function setAttackCalldata(bytes calldata cd) external {
        _attackCalldata = cd;
    }

    /// @notice Trigger tấn công bằng cách gọi hàm bridgeOut
    function attack(
        uint256 _amount,
        uint16  _destChainId,
        bytes32 _recipient,
        uint256 _deadline,
        bytes   calldata _zkProof,
        bytes32 _kycCommitment
    ) external {
        // Approve token cho router
        IERC20(token).approve(target, _amount * 10);

        // Gọi bridgeOut — khi contract nhận ETH, sẽ trigger fallback
        (bool success, bytes memory err) = target.call(
            abi.encodeWithSignature(
                "bridgeOut(address,uint256,uint16,bytes32,uint256,bytes,bytes32)",
                token, _amount, _destChainId, _recipient, _deadline, _zkProof, _kycCommitment
            )
        );
        emit AttackAttempted(attackCount, success);
        if (!success) emit AttackFailed(string(err));
    }

    /// @notice Fallback: kích hoạt reentrant call khi nhận ETH/token callback
    fallback() external payable {
        _tryReenter();
    }

    receive() external payable {
        _tryReenter();
    }

    function _tryReenter() internal {
        if (!attackTriggered && _attackCalldata.length > 0) {
            attackTriggered = true;
            attackCount++;

            // Cố gắng gọi lại router
            (bool success, bytes memory data) = target.call(_attackCalldata);

            emit AttackAttempted(attackCount, success);
            if (!success) {
                emit AttackFailed(string(data));
            }
            // Nếu success = true → ReentrancyGuard KHÔNG hoạt động → BUG!
        }
    }
}
