// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — Foundry Deploy Script
// Deploys AXQToken, AXQVestingVault, AXQGovernance to Localnet (Anvil)
// and writes contract addresses to script/addresses.json + .env.localnet
//
// Usage:
//   forge script script/Deploy.s.sol --rpc-url http://127.0.0.1:8545 \
//     --broadcast --private-key <ANVIL_PK_0>
//
//   Or via Makefile:
//     make deploy-localnet

pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AXQToken.sol";
import "../src/AXQVestingVault.sol";
import "../src/AXQGovernance.sol";

/**
 * @title  Deploy — AXIOLEDGER Localnet Genesis
 * @notice Deploys the full contract suite to Anvil and writes address output.
 *
 * Vault setup (localnet — all vaults are controlled by the deployer for testing):
 *   - vpxSubsidy, rdTreasury, rwaReserve → Anvil test accounts 1-3
 *   - teamVesting                        → AXQVestingVault contract
 *   - strategic, tge                     → Anvil test accounts 4-5
 *   - dao (AXQToken owner)               → AXQGovernance contract
 *   - guardians                          → Anvil test accounts 6-10
 *
 * After deployment, genesisAllocate() is called to mint 500B AXQ.
 */
contract Deploy is Script {

    // ── Anvil deterministic addresses (private key = keccak256(index)) ───────

    // anvil --mnemonic "test test test test test test test test test test test junk"
    address constant ANVIL_0  = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // deployer
    address constant ANVIL_1  = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant ANVIL_2  = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant ANVIL_3  = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address constant ANVIL_4  = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address constant ANVIL_5  = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
    address constant ANVIL_6  = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
    address constant ANVIL_7  = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    address constant ANVIL_8  = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    address constant ANVIL_9  = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    address constant ANVIL_10 = 0xBcd4042DE499D14e55001CcbB24a551F3b954096;

    // Output file paths (relative to project root)
    string constant ADDR_JSON = "script/addresses.json";
    string constant ENV_FILE  = ".env.localnet";

    function run() external {
        vm.startBroadcast();

        // ── 1. Deploy AXQVestingVault ─────────────────────────────────────────
        // Constructor: (token address) — set after token deploy, so we use address(0)
        // then update via setToken() if needed. For simplicity on localnet,
        // we deploy vault first and patch via genesisAllocate order.
        //
        // AXQVestingVault constructor requires the AXQ token address.
        // We deploy a placeholder then deploy Token pointing at a known address.
        // Simplest approach: predict token address using CREATE then deploy both.

        uint256 deployerNonce = vm.getNonce(ANVIL_0);

        // Token will be deployed at nonce=deployerNonce (first deployment)
        address predictedToken = computeCreateAddress(ANVIL_0, deployerNonce);
        console.log("Predicted AXQToken address:", predictedToken);

        // ── 2. Deploy AXQToken ────────────────────────────────────────────────
        // teamVestingVault = predictedVault (nonce+1), dao = predictedGovernance (nonce+2)
        address predictedVault = computeCreateAddress(ANVIL_0, deployerNonce + 1);
        address predictedGov   = computeCreateAddress(ANVIL_0, deployerNonce + 2);

        AXQToken token = new AXQToken(
            ANVIL_1,          // vpxSubsidyVault
            ANVIL_2,          // rdTreasuryVault  ← sweep target in treasury-sweep.js
            ANVIL_3,          // rwaReserveVault
            predictedVault,   // teamVestingVault  ← AXQVestingVault (deployed next)
            ANVIL_4,          // strategicVault
            ANVIL_5,          // tgeVault
            predictedGov      // dao / owner       ← AXQGovernance (deployed after)
        );
        require(address(token) == predictedToken, "Deploy: token address mismatch");
        console.log("AXQToken deployed at:", address(token));

        // ── 3. Deploy AXQVestingVault ─────────────────────────────────────────
        // Constructor: (_axqToken, _treasury, _dao)
        // dao = predictedGov — DAO will own the vault and add/revoke grants
        AXQVestingVault vault = new AXQVestingVault(address(token), ANVIL_2, predictedGov);
        require(address(vault) == predictedVault, "Deploy: vault address mismatch");
        console.log("AXQVestingVault deployed at:", address(vault));

        // ── 4. Deploy AXQGovernance ───────────────────────────────────────────
        address[5] memory guardians = [ANVIL_6, ANVIL_7, ANVIL_8, ANVIL_9, ANVIL_10];

        AXQGovernance governance = new AXQGovernance(
            address(token),
            ANVIL_2,    // treasury = rdTreasury
            guardians
        );
        require(address(governance) == predictedGov, "Deploy: governance address mismatch");
        console.log("AXQGovernance deployed at:", address(governance));

        // ── 5. Genesis allocation ─────────────────────────────────────────────
        // At this point governance IS the owner of token (passed as _dao).
        // But governance is a contract, not an EOA — we need to call genesisAllocate
        // through a governance proposal OR have the deployer as temporary owner.
        //
        // Localnet shortcut: token was deployed with predictedGov as owner.
        // Since governance is not yet functional (no tokens delegated), we
        // call genesisAllocate directly from the deployer by making the deployer
        // the initial owner and transferring after. Override: use ANVIL_0 as dao.
        //
        // NOTE: For Localnet only — production genesis uses a multisig ceremony.
        // Re-deploy with _dao = ANVIL_0 for localnet testing:
        console.log("");
        console.log("NOTE: On localnet, use ANVIL_0 as _dao to call genesisAllocate().");
        console.log("      See the localnet override below.");
        console.log("");

        vm.stopBroadcast();

        // ── 6. Write addresses.json ───────────────────────────────────────────
        string memory nl  = "\n";
        string memory json = string.concat(
            "{", nl,
            '  "network": "localnet",', nl,
            '  "chainId": 31337,', nl,
            '  "deployedAt": "', vm.toString(block.timestamp), '",', nl,
            '  "contracts": {', nl,
            '    "axqToken":      "', vm.toString(address(token)),      '",', nl,
            '    "axqVesting":    "', vm.toString(address(vault)),      '",', nl,
            '    "axqGovernance": "', vm.toString(address(governance)), '",', nl,
            '    "rdTreasury":    "', vm.toString(ANVIL_2),             '",', nl,
            '    "vpxSubsidy":    "', vm.toString(ANVIL_1),             '",', nl,
            '    "rwaReserve":    "', vm.toString(ANVIL_3),             '",', nl,
            '    "strategic":     "', vm.toString(ANVIL_4),             '",', nl,
            '    "tge":           "', vm.toString(ANVIL_5),             '"', nl,
            '  },', nl,
            '  "guardians": [', nl,
            '    "', vm.toString(ANVIL_6),  '",', nl,
            '    "', vm.toString(ANVIL_7),  '",', nl,
            '    "', vm.toString(ANVIL_8),  '",', nl,
            '    "', vm.toString(ANVIL_9),  '",', nl,
            '    "', vm.toString(ANVIL_10), '"', nl,
            '  ]', nl,
            '}'
        );
        vm.writeFile(ADDR_JSON, json);
        console.log("Addresses written to:", ADDR_JSON);

        // ── 7. Write .env.localnet ────────────────────────────────────────────
        string memory envContent = string.concat(
            unicode"# AXIOLEDGER Localnet - auto-generated by Deploy.s.sol", nl,
            "# DO NOT COMMIT - contains localnet addresses only", nl,
            nl,
            "NEXT_PUBLIC_NETWORK=localnet", nl,
            "NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545", nl,
            "NEXT_PUBLIC_CHAIN_ID=31337", nl,
            nl,
            "NEXT_PUBLIC_AXQ_TOKEN=",      vm.toString(address(token)),      nl,
            "NEXT_PUBLIC_AXQ_VESTING=",    vm.toString(address(vault)),      nl,
            "NEXT_PUBLIC_AXQ_GOVERNANCE=", vm.toString(address(governance)), nl,
            "NEXT_PUBLIC_RD_TREASURY=",    vm.toString(ANVIL_2),             nl,
            nl,
            "# Treasury sweep operator config", nl,
            "AXQ_TOKEN_ADDRESS=",          vm.toString(address(token)),      nl,
            "SWEEP_TARGET=",               vm.toString(ANVIL_2),             nl,
            "AXQ_RPC_URL=http://127.0.0.1:8545", nl,
            "# SWEEP_PRIVATE_KEY= <- set from secret manager", nl,
            "# SWEEP_SOURCES=     <- comma-separated vault addresses to sweep", nl
        );
        vm.writeFile(ENV_FILE, envContent);
        console.log(".env.localnet written to:", ENV_FILE);

        // ── 8. Summary ────────────────────────────────────────────────────────
        console.log("");
        console.log("=== AXIOLEDGER LOCALNET DEPLOY SUMMARY ===");
        console.log("AXQToken:      ", address(token));
        console.log("AXQVestingVault:", address(vault));
        console.log("AXQGovernance: ", address(governance));
        console.log("rdTreasury:    ", ANVIL_2);
        console.log("");
        console.log("Next steps:");
        console.log("  1. Fund deployer with test ETH: anvil --balance 10000");
        console.log("  2. Call token.genesisAllocate() from the owner address");
        console.log("  3. Delegate votes: token.delegate(address) for each vault");
        console.log("  4. Import addresses.json into SDK config or .env.local");
        console.log("===========================================");
    }
}

// ── Localnet override script (genesisAllocate + delegation) ──────────────────
/**
 * @notice Run this AFTER Deploy.s.sol to complete genesis setup.
 *         Reads addresses from script/addresses.json.
 *
 *   forge script script/Deploy.s.sol:GenesisSetup \
 *     --rpc-url http://127.0.0.1:8545 --broadcast --private-key <ANVIL_PK_0>
 */
contract GenesisSetup is Script {

    address constant ANVIL_0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ANVIL_2 = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;

    function run() external {
        // Read addresses from the file written by Deploy
        string memory json   = vm.readFile("script/addresses.json");
        address tokenAddr    = abi.decode(vm.parseJson(json, ".contracts.axqToken"),    (address));
        address vestingAddr  = abi.decode(vm.parseJson(json, ".contracts.axqVesting"),  (address));
        address govAddr      = abi.decode(vm.parseJson(json, ".contracts.axqGovernance"), (address));

        console.log("Running genesis setup for AXQToken:", tokenAddr);

        vm.startBroadcast();

        AXQToken token = AXQToken(tokenAddr);

        // Localnet: token owner is ANVIL_0 (deployer) — call genesisAllocate
        token.genesisAllocate();
        console.log("genesisAllocate() called - 500B AXQ minted across vaults");

        // Self-delegate for rdTreasury so governance proposal threshold is met
        // (rdTreasury must have voting power > 100k AXQ threshold)
        // In localnet, ANVIL_2 controls rdTreasury — delegate to itself
        // Note: this broadcast is from ANVIL_0; rdTreasury delegation needs ANVIL_2's key
        console.log("Note: run `cast send <token> 'delegate(address)' <rdTreasury> --private-key <ANVIL_2_KEY>`");
        console.log("      to give rdTreasury self-delegated voting power.");

        vm.stopBroadcast();

        console.log("Genesis setup complete.");
        console.log("VestingVault:", vestingAddr, "(use addGrant() to vest team tokens)");
        console.log("Governance:  ", govAddr,    "(propose() requires 100k AXQ delegated)");
    }
}

// ── DeployLocalnet — One-shot script: deploy + genesisAllocate + delegate ────
/**
 * @notice Single-command localnet bootstrap. Deploys all contracts, calls
 *         genesisAllocate(), and self-delegates rdTreasury (ANVIL_2) so that
 *         governance proposals can be created immediately.
 *
 *   forge script script/Deploy.s.sol:DeployLocalnet \
 *     --rpc-url http://127.0.0.1:8545 --broadcast \
 *     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
 */
contract DeployLocalnet is Script {

    address constant ANVIL_0  = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address constant ANVIL_1  = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    address constant ANVIL_2  = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
    address constant ANVIL_3  = 0x90F79bf6EB2c4f870365E785982E1f101E93b906;
    address constant ANVIL_4  = 0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65;
    address constant ANVIL_5  = 0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc;
    address constant ANVIL_6  = 0x976EA74026E726554dB657fA54763abd0C3a0aa9;
    address constant ANVIL_7  = 0x14dC79964da2C08b23698B3D3cc7Ca32193d9955;
    address constant ANVIL_8  = 0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f;
    address constant ANVIL_9  = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;
    address constant ANVIL_10 = 0xBcd4042DE499D14e55001CcbB24a551F3b954096;
    // Anvil account 2 private key (for rdTreasury self-delegation)
    uint256 constant ANVIL_PK_2 = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    string constant ADDR_JSON = "script/addresses.json";
    string constant ENV_FILE  = ".env.localnet";

    function run() external {
        vm.startBroadcast();

        uint256 deployerNonce = vm.getNonce(ANVIL_0);

        // Predict addresses
        address predictedToken  = vm.computeCreateAddress(ANVIL_0, deployerNonce);
        address predictedVault  = vm.computeCreateAddress(ANVIL_0, deployerNonce + 1);
        address predictedGov    = vm.computeCreateAddress(ANVIL_0, deployerNonce + 2);

        // Deploy Token — owner = ANVIL_0 (deployer) so we can call genesisAllocate()
        // We will transfer ownership to governance after genesis.
        AXQToken token = new AXQToken(
            ANVIL_1,        // vpxSubsidyVault
            ANVIL_2,        // rdTreasuryVault
            ANVIL_3,        // rwaReserveVault
            predictedVault, // teamVestingVault
            ANVIL_4,        // strategicVault
            ANVIL_5,        // tgeVault
            ANVIL_0         // _dao = ANVIL_0 (temp owner for genesisAllocate)
        );
        require(address(token) == predictedToken, "token addr mismatch");

        // Deploy VestingVault — owner = predictedGov (governance will manage grants)
        AXQVestingVault vault = new AXQVestingVault(address(token), ANVIL_2, predictedGov);
        require(address(vault) == predictedVault, "vault addr mismatch");

        // Deploy Governance — owns vault and will own token after transfer
        address[5] memory guardians = [ANVIL_6, ANVIL_7, ANVIL_8, ANVIL_9, ANVIL_10];
        AXQGovernance governance = new AXQGovernance(address(token), ANVIL_2, guardians);
        require(address(governance) == predictedGov, "gov addr mismatch");

        // Genesis: mint 500B AXQ to all vaults (ANVIL_0 is owner)
        token.genesisAllocate();

        // Transfer token ownership to governance (2-step: initiate then accept)
        token.transferOwnership(address(governance));
        // Note: Ownable2Step requires governance to acceptOwnership().
        // On localnet we leave it pending — governance can accept via proposal.
        // For testing purposes ANVIL_0 retains pending owner status.

        vm.stopBroadcast();

        // Self-delegate rdTreasury (ANVIL_2) so it has voting power for proposals
        vm.startBroadcast(ANVIL_PK_2);
        token.delegate(ANVIL_2);
        vm.stopBroadcast();

        // ── Write output files ────────────────────────────────────────────────
        string memory nl = "\n";
        string memory json = string.concat(
            "{", nl,
            '  "network": "localnet",', nl,
            '  "chainId": 31337,', nl,
            '  "deployedAt": "', vm.toString(block.timestamp), '",', nl,
            '  "contracts": {', nl,
            '    "axqToken":      "', vm.toString(address(token)),      '",', nl,
            '    "axqVesting":    "', vm.toString(address(vault)),      '",', nl,
            '    "axqGovernance": "', vm.toString(address(governance)), '",', nl,
            '    "rdTreasury":    "', vm.toString(ANVIL_2), '",', nl,
            '    "vpxSubsidy":    "', vm.toString(ANVIL_1), '",', nl,
            '    "rwaReserve":    "', vm.toString(ANVIL_3), '",', nl,
            '    "strategic":     "', vm.toString(ANVIL_4), '",', nl,
            '    "tge":           "', vm.toString(ANVIL_5), '"', nl,
            '  },', nl,
            '  "guardians": [', nl,
            '    "', vm.toString(ANVIL_6),  '",', nl,
            '    "', vm.toString(ANVIL_7),  '",', nl,
            '    "', vm.toString(ANVIL_8),  '",', nl,
            '    "', vm.toString(ANVIL_9),  '",', nl,
            '    "', vm.toString(ANVIL_10), '"', nl,
            '  ]', nl,
            '}'
        );
        vm.writeFile(ADDR_JSON, json);

        string memory envContent = string.concat(
            "# AXIOLEDGER Localnet - auto-generated by DeployLocalnet", nl,
            "# DO NOT COMMIT", nl,
            nl,
            "NEXT_PUBLIC_NETWORK=localnet", nl,
            "NEXT_PUBLIC_RPC_URL=http://127.0.0.1:8545", nl,
            "NEXT_PUBLIC_CHAIN_ID=31337", nl,
            nl,
            "NEXT_PUBLIC_AXQ_TOKEN=",      vm.toString(address(token)),      nl,
            "NEXT_PUBLIC_AXQ_VESTING=",    vm.toString(address(vault)),      nl,
            "NEXT_PUBLIC_AXQ_GOVERNANCE=", vm.toString(address(governance)), nl,
            "NEXT_PUBLIC_RD_TREASURY=",    vm.toString(ANVIL_2),             nl,
            nl,
            "# Treasury sweep config", nl,
            "AXQ_TOKEN_ADDRESS=",          vm.toString(address(token)),      nl,
            "SWEEP_TARGET=",               vm.toString(ANVIL_2),             nl,
            "AXQ_RPC_URL=http://127.0.0.1:8545", nl
        );
        vm.writeFile(ENV_FILE, envContent);

        console.log("=== AXIOLEDGER LOCALNET GENESIS COMPLETE ===");
        console.log("AXQToken:      ", address(token));
        console.log("AXQVestingVault:", address(vault));
        console.log("AXQGovernance: ", address(governance));
        console.log("rdTreasury:    ", ANVIL_2, "(self-delegated, voting power active)");
        console.log("500B AXQ minted and distributed across all vaults.");
        console.log("addresses.json written to: script/addresses.json");
        console.log("============================================");
    }
}
