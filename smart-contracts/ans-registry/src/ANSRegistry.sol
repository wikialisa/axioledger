// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — AXIOLEDGER Name Service (ANS) Registry
// Supports TLDs: .axq | .vpx | .sqx | .kpx | .vrq
//
// Architecture:
//   - Domain = keccak256(label) mapped to Registration
//   - Each domain resolves to a primary address + optional metadata
//   - DAO controls TLD registration fees and namespace rules
//
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ANSRegistry — AXIOLEDGER Name Service
/// @notice Register and resolve short human-readable names on AXIOLEDGER.
contract ANSRegistry is Ownable2Step, ReentrancyGuard {

    // ── Types ────────────────────────────────────────────────────────────────

    struct Registration {
        address owner;
        address resolver;
        uint64  expiry;      // Unix timestamp
        bool    locked;      // Guardian-locked name (anti-squatting)
    }

    // ── Constants ────────────────────────────────────────────────────────────

    uint64  public constant REGISTRATION_PERIOD = 365 days;
    uint256 public constant MIN_LABEL_LENGTH    = 3;
    uint256 public constant MAX_LABEL_LENGTH    = 63;

    // ── State ────────────────────────────────────────────────────────────────

    /// nameHash → Registration
    mapping(bytes32 => Registration) public records;

    /// TLD → fee (in wei)
    mapping(bytes32 => uint256) public tldFees;

    /// Registered TLDs
    mapping(bytes32 => bool) public supportedTlds;

    /// Address → list of owned nameHashes (for enumeration)
    mapping(address => bytes32[]) private _ownedNames;

    address public treasury;

    // ── Events ───────────────────────────────────────────────────────────────

    event NameRegistered(bytes32 indexed nameHash, string label, string tld, address owner, uint64 expiry);
    event NameRenewed(bytes32 indexed nameHash, uint64 newExpiry);
    event NameTransferred(bytes32 indexed nameHash, address from, address to);
    event ResolverSet(bytes32 indexed nameHash, address resolver);
    event TldAdded(bytes32 indexed tldHash, string tld, uint256 fee);

    // ── Errors ───────────────────────────────────────────────────────────────

    error ANS_InvalidLabel();
    error ANS_UnsupportedTld();
    error ANS_AlreadyRegistered();
    error ANS_NotOwner();
    error ANS_NameExpired();
    error ANS_NameLocked();
    error ANS_InsufficientFee();
    error ANS_ZeroAddress();

    // ── Constructor ──────────────────────────────────────────────────────────

    constructor(address _treasury, address _dao) Ownable(_dao) {
        if (_treasury == address(0)) revert ANS_ZeroAddress();
        treasury = _treasury;

        // Register initial TLDs
        _addTld("axq", 0.01 ether);
        _addTld("vpx", 0.01 ether);
        _addTld("sqx", 0.01 ether);
        _addTld("kpx", 0.01 ether);
        _addTld("vrq", 0.01 ether);
    }

    // ── Registration ─────────────────────────────────────────────────────────

    /// @notice Register `label.tld` for one year.
    function register(
        string calldata label,
        string calldata tld,
        address resolver
    ) external payable nonReentrant {
        bytes32 tldHash  = keccak256(bytes(tld));
        bytes32 nameHash = _nameHash(label, tld);

        if (!supportedTlds[tldHash])                   revert ANS_UnsupportedTld();
        if (!_validLabel(label))                        revert ANS_InvalidLabel();
        if (_isActive(nameHash))                        revert ANS_AlreadyRegistered();
        if (msg.value < tldFees[tldHash])               revert ANS_InsufficientFee();

        uint64 expiry = uint64(block.timestamp) + REGISTRATION_PERIOD;

        records[nameHash] = Registration({
            owner:    msg.sender,
            resolver: resolver,
            expiry:   expiry,
            locked:   false
        });

        _ownedNames[msg.sender].push(nameHash);

        // Forward fee to treasury
        (bool ok, ) = treasury.call{ value: msg.value }("");
        require(ok, "treasury transfer failed");

        emit NameRegistered(nameHash, label, tld, msg.sender, expiry);
    }

    /// @notice Renew a name for another year.
    function renew(string calldata label, string calldata tld) external payable nonReentrant {
        bytes32 tldHash  = keccak256(bytes(tld));
        bytes32 nameHash = _nameHash(label, tld);

        if (!supportedTlds[tldHash])        revert ANS_UnsupportedTld();
        if (records[nameHash].locked)       revert ANS_NameLocked();
        if (msg.value < tldFees[tldHash])   revert ANS_InsufficientFee();

        Registration storage reg = records[nameHash];
        uint64 base  = reg.expiry > uint64(block.timestamp) ? reg.expiry : uint64(block.timestamp);
        reg.expiry   = base + REGISTRATION_PERIOD;

        (bool ok, ) = treasury.call{ value: msg.value }("");
        require(ok, "treasury transfer failed");

        emit NameRenewed(nameHash, reg.expiry);
    }

    // ── Resolution ───────────────────────────────────────────────────────────

    /// @notice Resolve `label.tld` to its owner address.
    function resolve(string calldata label, string calldata tld) external view returns (address) {
        bytes32 nameHash = _nameHash(label, tld);
        if (!_isActive(nameHash)) revert ANS_NameExpired();
        return records[nameHash].owner;
    }

    /// @notice Resolve to the resolver contract (for extended records).
    function getResolver(string calldata label, string calldata tld) external view returns (address) {
        bytes32 nameHash = _nameHash(label, tld);
        if (!_isActive(nameHash)) revert ANS_NameExpired();
        return records[nameHash].resolver;
    }

    // ── Owner actions ─────────────────────────────────────────────────────────

    function setResolver(string calldata label, string calldata tld, address resolver) external {
        bytes32 nameHash = _nameHash(label, tld);
        if (records[nameHash].owner != msg.sender) revert ANS_NotOwner();
        if (records[nameHash].locked)              revert ANS_NameLocked();
        records[nameHash].resolver = resolver;
        emit ResolverSet(nameHash, resolver);
    }

    function transfer(string calldata label, string calldata tld, address to) external {
        bytes32 nameHash = _nameHash(label, tld);
        if (records[nameHash].owner != msg.sender) revert ANS_NotOwner();
        if (records[nameHash].locked)              revert ANS_NameLocked();
        if (to == address(0))                      revert ANS_ZeroAddress();

        address from = msg.sender;
        records[nameHash].owner = to;
        _ownedNames[to].push(nameHash);
        emit NameTransferred(nameHash, from, to);
    }

    // ── DAO actions ──────────────────────────────────────────────────────────

    function addTld(string calldata tld, uint256 fee) external onlyOwner {
        _addTld(tld, fee);
    }

    function setTldFee(string calldata tld, uint256 fee) external onlyOwner {
        tldFees[keccak256(bytes(tld))] = fee;
    }

    function lockName(bytes32 nameHash, bool locked) external onlyOwner {
        records[nameHash].locked = locked;
    }

    function setTreasury(address _treasury) external onlyOwner {
        if (_treasury == address(0)) revert ANS_ZeroAddress();
        treasury = _treasury;
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    function _addTld(string memory tld, uint256 fee) internal {
        bytes32 tldHash = keccak256(bytes(tld));
        supportedTlds[tldHash] = true;
        tldFees[tldHash]       = fee;
        emit TldAdded(tldHash, tld, fee);
    }

    function _nameHash(string calldata label, string calldata tld) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(keccak256(bytes(label)), keccak256(bytes(tld))));
    }

    function _isActive(bytes32 nameHash) internal view returns (bool) {
        Registration storage reg = records[nameHash];
        return reg.owner != address(0) && reg.expiry > block.timestamp;
    }

    function _validLabel(string calldata label) internal pure returns (bool) {
        bytes memory b = bytes(label);
        if (b.length < MIN_LABEL_LENGTH || b.length > MAX_LABEL_LENGTH) return false;
        for (uint256 i = 0; i < b.length; ) {
            bytes1 c = b[i];
            bool valid = (c >= 0x61 && c <= 0x7A)  // a-z
                      || (c >= 0x30 && c <= 0x39)  // 0-9
                      || (c == 0x2D && i != 0 && i != b.length - 1); // hyphen (not at start/end)
            if (!valid) return false;
            unchecked { i++; }
        }
        return true;
    }
}
