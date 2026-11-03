// SPDX-License-Identifier: MIT
// DeployLocalnet.s.sol — Deploy entire AXIOLEDGER stack to Anvil
//
// Usage:
//   forge script script/DeployLocalnet.s.sol \
//     --rpc-url http://127.0.0.1:8545 \
//     --broadcast \
//     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
//
// The private key above is Anvil account 0 (deployer/dao) — default Anvil mnemonic.
// NEVER use this key on mainnet or testnet.

pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../smart-contracts/axioledger-system/src/AXQToken.sol";
import "../smart-contracts/axioledger-system/src/AXQGovernance.sol";
import "../smart-contracts/axioledger-system/src/AXQVestingVault.sol";
import "../smart-contracts/ans-registry/src/ANSRegistry.sol";

// ── Minimal VRQVerifier stub (localnet only) ──────────────────────────────────
// In production, the real IVRQVerifier is deployed on Sepolia.
// For localnet testing, this stub approves all proofs and flags no addresses.
contract LocalnetVRQVerifierStub {
    function isFlagged(address) external pure returns (bool) { return false; }
    function verifyCompliance(bytes calldata, bytes32) external pure returns (bool) { return true; }
    function circuitVersion() external pure returns (uint256) { return 1; }
}

// ── Minimal VRQPasskeyValidator (import from vrq-circuits) ───────────────────
// We only need to deploy the contract — actual P256 verification is skipped on Anvil
// because the Daimo P256Verifier precompile isn't available locally.
// Instead we use a PasskeyValidatorStub that accepts any signature.
contract PasskeyValidatorStub {
    address public immutable zkVerifier;
    mapping(address => uint256) public accountPubKeyX;
    mapping(address => uint256) public accountPubKeyY;
    mapping(address => bool)    private _installed;

    event ValidatorInstalled(address indexed account, uint256 pubKeyX, uint256 pubKeyY);
    event ValidatorUninstalled(address indexed account);

    constructor(address _zkVerifier) { zkVerifier = _zkVerifier; }

    function onInstall(bytes calldata data) external {
        (uint256 x, uint256 y,,) = abi.decode(data, (uint256, uint256, bytes32, bytes));
        accountPubKeyX[msg.sender] = x;
        accountPubKeyY[msg.sender] = y;
        _installed[msg.sender] = true;
        emit ValidatorInstalled(msg.sender, x, y);
    }

    function onUninstall(bytes calldata) external {
        delete accountPubKeyX[msg.sender];
        delete accountPubKeyY[msg.sender];
        delete _installed[msg.sender];
        emit ValidatorUninstalled(msg.sender);
    }

    function isInitialized(address a) external view returns (bool) { return _installed[a]; }
    function isModuleType(uint256 id) external pure returns (bool) { return id == 1; }

    // Localnet: always validates (no real P256 check)
    function validateUserOp(bytes calldata, bytes32) external pure returns (uint256) { return 0; }
    function isValidSignatureWithSender(address, bytes32, bytes calldata) external pure returns (bytes4) {
        return 0x1626ba7e;
    }
}

// ── Deploy Script ─────────────────────────────────────────────────────────────

contract DeployLocalnet is Script {

    // Anvil default accounts (deterministic from mnemonic: test test test ... junk)
    address constant DEPLOYER   = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant GUARDIAN_1 = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant GUARDIAN_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant GUARDIAN_3 = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address constant GUARDIAN_4 = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address constant GUARDIAN_5 = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
    address constant TEST_USER  = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;

    function run() external {
        uint256 deployerKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerKey);

        // ── 1. VRQ Stub (localnet compliance verifier) ────────────────────────
        LocalnetVRQVerifierStub vrqStub = new LocalnetVRQVerifierStub();
        console.log("VRQVerifierStub     :", address(vrqStub));

        // ── 2. AXQToken ───────────────────────────────────────────────────────
        // Treasury = DEPLOYER for localnet simplicity
        AXQToken axqToken = new AXQToken(
            DEPLOYER,   // vpxSubsidy
            DEPLOYER,   // rdTreasury
            DEPLOYER,   // rwaReserve
            DEPLOYER,   // teamVesting (would be AXQVestingVault in prod)
            DEPLOYER,   // strategic
            DEPLOYER,   // tge
            DEPLOYER    // dao (owner)
        );
        console.log("AXQToken            :", address(axqToken));

        // ── 3. Genesis allocate — mint 500B AXQ to DEPLOYER vaults ───────────
        axqToken.genesisAllocate();
        console.log("Genesis allocation  : done — 500B AXQ minted");

        // ── 4. Fund TEST_USER with 1M AXQ for testing ─────────────────────────
        // Transfer from RD Treasury allocation (DEPLOYER holds all vaults)
        axqToken.transfer(TEST_USER, 1_000_000e18);
        console.log("Faucet to TEST_USER : 1,000,000 AXQ");

        // ── 5. AXQGovernance ──────────────────────────────────────────────────
        address[5] memory guardians = [GUARDIAN_1, GUARDIAN_2, GUARDIAN_3, GUARDIAN_4, GUARDIAN_5];
        AXQGovernance governance = new AXQGovernance(
            address(axqToken),
            DEPLOYER,   // treasury
            guardians
        );
        console.log("AXQGovernance       :", address(governance));

        // ── 6. ANSRegistry ────────────────────────────────────────────────────
        ANSRegistry ansRegistry = new ANSRegistry(
            DEPLOYER,   // treasury
            DEPLOYER    // dao
        );
        console.log("ANSRegistry         :", address(ansRegistry));

        // Register test names for E2E testing
        // alice.axq → DEPLOYER
        axqToken.approve(address(ansRegistry), 1 ether);
        ansRegistry.register{value: 0.01 ether}("alice", "axq", address(0));
        console.log("ANS registered      : alice.axq -> DEPLOYER");

        // testuser.axq → TEST_USER
        ansRegistry.register{value: 0.01 ether}("testuser", "axq", address(0));
        console.log("ANS registered      : testuser.axq -> DEPLOYER (transfer in E2E)");

        // pool.kpx → DEPLOYER (for TLP caution test)
        ansRegistry.register{value: 0.01 ether}("pool", "kpx", address(0));
        console.log("ANS registered      : pool.kpx -> DEPLOYER (TLP caution test)");

        // ── 7. VRQPasskeyValidator (localnet stub) ────────────────────────────
        PasskeyValidatorStub vrqValidator = new PasskeyValidatorStub(address(vrqStub));
        console.log("VRQPasskeyValidator :", address(vrqValidator));

        vm.stopBroadcast();

        // ── Summary ───────────────────────────────────────────────────────────
        console.log("\n====================================================");
        console.log("  AXIOLEDGER LOCALNET DEPLOYMENT COMPLETE");
        console.log("====================================================");
        console.log("Copy these to apps/*/.env.local:");
        console.log("");
        console.log("NEXT_PUBLIC_AXQ_TOKEN=", address(axqToken));
        console.log("NEXT_PUBLIC_ANS_REGISTRY=", address(ansRegistry));
        console.log("NEXT_PUBLIC_AXQ_GOVERNANCE=", address(governance));
        console.log("NEXT_PUBLIC_VRQ_VALIDATOR=", address(vrqValidator));
        console.log("");
        console.log("Test accounts:");
        console.log("  DEPLOYER  (DAO owner):", DEPLOYER);
        console.log("  TEST_USER (1M AXQ)   :", TEST_USER);
        console.log("====================================================");
    }
}
