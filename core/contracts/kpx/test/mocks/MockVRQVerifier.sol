// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../interfaces/IVRQVerifier.sol";

/// @notice Mock VRQ Verifier — kiểm soát được từ test để mô phỏng các kịch bản
contract MockVRQVerifier is IVRQVerifier {
    mapping(address => bool) private _flagged;
    bool public proofResult   = true;   // Default: proof hợp lệ
    bool public complianceResult = true; // Default: compliance pass
    uint256 public _circuitVersion = 1;

    // ─── Test controls ───────────────────────────────────────────────────────
    function setFlagged(address addr, bool flag) external { _flagged[addr] = flag; }
    function setProofResult(bool result) external { proofResult = result; }
    function setComplianceResult(bool result) external { complianceResult = result; }
    function setCircuitVersion(uint256 v) external { _circuitVersion = v; }

    // ─── IVRQVerifier ────────────────────────────────────────────────────────
    function isFlagged(address addr) external view override returns (bool) {
        return _flagged[addr];
    }

    function verifyProof(bytes calldata, uint256[] calldata)
        external view override returns (bool)
    {
        return proofResult;
    }

    function verifyCompliance(bytes calldata, bytes32)
        external view override returns (bool)
    {
        return complianceResult;
    }

    function circuitVersion() external view override returns (uint256) {
        return _circuitVersion;
    }

    function isTxSafe(bytes32) external pure override returns (bool) {
        return true;
    }
}
