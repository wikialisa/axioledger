// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER - VERACIPHERS ($VRQ)
// VRQPasskeyValidator.sol - ZeroDev Kernel Plugin (ERC-7579 IValidator)
//
// +====================================================================+
// |  LAYER STACK                                                       |
// |  ① EntryPoint v0.9   - eth-infinitism/account-abstraction         |
// |  ② KernelUUPS        - zerodevapp/kernel (ERC-7579)               |
// |  ③ THIS MODULE       - VRQPasskeyValidator (Validator type=1)     |
// |     ├─ Gate 1: zkVerifier.isFlagged()  → VRQ blacklist            |
// |     └─ Gate 2: WebAuthn.verifySignature() → Daimo P256 on-chain   |
// |  ④ KPXRouterGateway  - AXIOLEDGER routing / bridge / swap         |
// +====================================================================+
//
// ERC-7579 module type : MODULE_TYPE_VALIDATOR = 1
// PackedUserOperation  : eth-infinitism v0.9 (bytes32 accountGasLimits)
// P256 verifier addr   : 0xc2b78104907F722DABAc4C69f826a522B2754De4  (deterministic CREATE2)
// Deployed on Sepolia  : see /core/contracts/vrq/broadcast/
//
pragma solidity ^0.8.28;

// ---------------------------------------------------------------------------
// Interfaces (vendored to avoid import-path coupling in monorepo)
// ---------------------------------------------------------------------------

interface IValidator {
    function onInstall(bytes calldata data) external payable;
    function onUninstall(bytes calldata data) external payable;
    function isModuleType(uint256 moduleTypeId) external view returns (bool);
    function isInitialized(address smartAccount) external view returns (bool);
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash)
        external payable returns (uint256);
    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata data)
        external view returns (bytes4);
}

struct PackedUserOperation {
    address  sender;
    uint256  nonce;
    bytes    initCode;
    bytes    callData;
    bytes32  accountGasLimits;
    uint256  preVerificationGas;
    bytes32  gasFees;
    bytes    paymasterAndData;
    bytes    signature;
}

interface IVRQVerifier {
    function isFlagged(address addr)            external view returns (bool);
    function verifyCompliance(bytes calldata proof, bytes32 kycCommitment)
                                                external view returns (bool);
    function circuitVersion()                   external view returns (uint256);
}

// ---------------------------------------------------------------------------
// VRQPasskeyValidator
// ---------------------------------------------------------------------------

/**
 * @title  VRQPasskeyValidator
 * @author AXIOLEDGER Core Team
 * @notice ERC-7579 Validator module for ZeroDev KernelUUPS.
 *
 *         Gate 1 — Legal Compliance (VRQ):
 *           zkVerifier.isFlagged(userOp.sender) == false
 *
 *         Gate 2 — Biometric Authentication (Passkeys / WebAuthn):
 *           WebAuthn secp256r1 signature verified against P256 key stored on-chain.
 *           Uses Daimo P256Verifier at deterministic CREATE2 address.
 *
 * @dev    Installation:
 *         account.installModule(abi.encode(pubKeyX, pubKeyY, kycCommitment, zkProof))
 *
 *         Signature encoding (userOp.signature):
 *         abi.encode(authenticatorData, requireUserVerification, clientDataJSON,
 *                    challengeLocation, responseTypeLocation, r, s)
 */
contract VRQPasskeyValidator is IValidator {

    uint256 private constant MODULE_TYPE_VALIDATOR = 1;
    uint256 private constant SIG_VALIDATION_SUCCESS = 0;
    uint256 private constant SIG_VALIDATION_FAILED  = 1;
    bytes4  private constant ERC1271_MAGIC_VALUE  = 0x1626ba7e;
    bytes4  private constant ERC1271_INVALID      = 0xffffffff;
    address private constant P256_VERIFIER = 0xc2b78104907F722DABAc4C69f826a522B2754De4;

    IVRQVerifier public immutable zkVerifier;

    mapping(address => uint256) public accountPubKeyX;
    mapping(address => uint256) public accountPubKeyY;
    mapping(address => bool)    private _installed;

    event ValidatorInstalled(address indexed account, uint256 pubKeyX, uint256 pubKeyY);
    event ValidatorUninstalled(address indexed account);

    error VRQ_AccountFlagged(address account);
    error VRQ_ComplianceFailed();
    error VRQ_InvalidPubKey();
    error VRQ_AlreadyInstalled();
    error VRQ_NotInstalled();

    constructor(address _zkVerifier) {
        require(_zkVerifier != address(0), "VRQ: zero address");
        zkVerifier = IVRQVerifier(_zkVerifier);
    }

    // ── ERC-7579 lifecycle ───────────────────────────────────────────────────

    function onInstall(bytes calldata data) external payable override {
        if (_installed[msg.sender]) revert VRQ_AlreadyInstalled();

        (uint256 pubKeyX, uint256 pubKeyY, bytes32 kycCommitment, bytes memory zkProof)
            = abi.decode(data, (uint256, uint256, bytes32, bytes));

        if (pubKeyX == 0 || pubKeyY == 0) revert VRQ_InvalidPubKey();
        if (!zkVerifier.verifyCompliance(zkProof, kycCommitment)) revert VRQ_ComplianceFailed();

        accountPubKeyX[msg.sender] = pubKeyX;
        accountPubKeyY[msg.sender] = pubKeyY;
        _installed[msg.sender]     = true;

        emit ValidatorInstalled(msg.sender, pubKeyX, pubKeyY);
    }

    function onUninstall(bytes calldata) external payable override {
        if (!_installed[msg.sender]) revert VRQ_NotInstalled();
        delete accountPubKeyX[msg.sender];
        delete accountPubKeyY[msg.sender];
        delete _installed[msg.sender];
        emit ValidatorUninstalled(msg.sender);
    }

    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isInitialized(address smartAccount) external view override returns (bool) {
        return _installed[smartAccount];
    }

    // ── ERC-4337 validation ──────────────────────────────────────────────────

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external payable override returns (uint256) {
        if (zkVerifier.isFlagged(userOp.sender)) return SIG_VALIDATION_FAILED;
        return _verifyWebAuthnSignature(userOp.sender, userOpHash, userOp.signature)
            ? SIG_VALIDATION_SUCCESS
            : SIG_VALIDATION_FAILED;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {
        if (zkVerifier.isFlagged(sender)) return ERC1271_INVALID;
        return _verifyWebAuthnSignature(sender, hash, data)
            ? ERC1271_MAGIC_VALUE
            : ERC1271_INVALID;
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _verifyWebAuthnSignature(address account, bytes32 challenge, bytes calldata sig)
        internal view returns (bool)
    {
        uint256 pubX = accountPubKeyX[account];
        uint256 pubY = accountPubKeyY[account];
        if (pubX == 0 || pubY == 0) return false;
        if (sig.length < 32)        return false;

        (
            bytes memory authenticatorData,
            bool requireUserVerification,
            string memory clientDataJSON,
            uint256 challengeLocation,
            uint256 responseTypeLocation,
            uint256 r,
            uint256 s
        ) = abi.decode(sig, (bytes, bool, string, uint256, uint256, uint256, uint256));

        if (authenticatorData.length < 37) return false;
        bytes1 flags = authenticatorData[32];
        if (flags & 0x01 != 0x01) return false;
        if (requireUserVerification && (flags & 0x04 != 0x04)) return false;

        if (!_contains('"type":"webauthn.get"', clientDataJSON, responseTypeLocation)) return false;

        string memory challengeB64   = _base64urlEncode(abi.encodePacked(challenge));
        string memory challengeProp  = string(abi.encodePacked('"challenge":"', challengeB64, '"'));
        if (!_contains(challengeProp, clientDataJSON, challengeLocation)) return false;

        bytes32 clientDataHash = sha256(bytes(clientDataJSON));
        bytes32 messageHash    = sha256(abi.encodePacked(authenticatorData, clientDataHash));

        return _p256Verify(messageHash, r, s, pubX, pubY);
    }

    function _p256Verify(bytes32 messageHash, uint256 r, uint256 s, uint256 x, uint256 y)
        internal view returns (bool)
    {
        (bool ok, bytes memory result) = P256_VERIFIER.staticcall(abi.encode(messageHash, r, s, x, y));
        if (!ok || result.length < 32) return false;
        return abi.decode(result, (uint256)) == 1;
    }

    function _contains(string memory substr, string memory str, uint256 location)
        internal pure returns (bool)
    {
        bytes memory sub = bytes(substr);
        bytes memory s_  = bytes(str);
        if (location + sub.length > s_.length) return false;
        for (uint256 i = 0; i < sub.length; i++) {
            if (s_[location + i] != sub[i]) return false;
        }
        return true;
    }

    function _base64urlEncode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        bytes memory TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        uint256 ri = 0;
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 a = uint8(data[i]);
            uint256 b = i + 1 < data.length ? uint8(data[i + 1]) : 0;
            uint256 c = i + 2 < data.length ? uint8(data[i + 2]) : 0;
            uint256 triple = (a << 16) | (b << 8) | c;
            result[ri++] = TABLE[(triple >> 18) & 0x3F];
            result[ri++] = TABLE[(triple >> 12) & 0x3F];
            result[ri++] = TABLE[(triple >>  6) & 0x3F];
            result[ri++] = TABLE[ triple        & 0x3F];
        }
        uint256 finalLen = encodedLen;
        if (data.length % 3 == 1)      finalLen -= 2;
        else if (data.length % 3 == 2) finalLen -= 1;
        bytes memory trimmed = new bytes(finalLen);
        for (uint256 i = 0; i < finalLen; i++) trimmed[i] = result[i];
        return string(trimmed);
    }
}
