// SPDX-License-Identifier: BSL-1.1
// AXIOLEDGER — Sepolia Staging Deploy Script
//
// Deploys AXQToken, AXQVestingVault, AXQGovernance to Sepolia testnet.
// Uses a real EOA deployer (not Anvil deterministic keys).
//
// Prerequisites:
//   1. Fund deployer 0xAf3D0febB24706912706660FB41D48Fc89548A53 with >= 0.05 SepoliaETH
//      -> faucet: https://sepoliafaucet.com / https://faucet.quicknode.com/ethereum/sepolia
//   2. Export environment variables (never hardcode):
//        export SEPOLIA_RPC_URL="https://eth-sepolia.g.alchemy.com/v2/<ALCHEMY_KEY>"
//        export SEPOLIA_DEPLOYER_PK="<private key for 0xAf3D0feb...53>"
//        export ETHERSCAN_API_KEY="<key for verification>"
//   3. Vault/guardian addresses below -- review before broadcasting.
//
// Deploy (dry-run first):
//   forge script script/DeployAxqSepolia.s.sol:DeployAxqSepolia \
//     --rpc-url $SEPOLIA_RPC_URL \
//     --private-key $SEPOLIA_DEPLOYER_PK \
//     --chain-id 11155111 \
//     [--broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY]
//
// After deploy:
//   1. Call genesisAllocate() via DeployAxqSepoliaGenesis script below
//   2. Transfer token ownership to governance via proposal or deployer
//   3. Update identity-declaration.json with deployed contract addresses
//   4. Update apps .env.sepolia files

pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";

import "../src/AXQToken.sol";
import "../src/AXQVestingVault.sol";
import "../src/AXQGovernance.sol";

// ── Sepolia Vault & Guardian Configuration ────────────────────────────────────
//
// On Sepolia these are the deployer (0xAf3D0feb...53) acting as all vaults for
// initial testing. Replace with real multisig/cold wallet addresses before
// mainnet migration.
//
// VAULT ROLES:
//   VPX_SUBSIDY_VAULT    — Validator reward distribution (Valiprecision team)
//   RD_TREASURY_VAULT    — R&D + Protocol treasury (AXIOLEDGER Foundation multisig)
//   RWA_RESERVE_VAULT    — RWA-backed reserve (Kineto SPV multisig)
//   STRATEGIC_VAULT      — Strategic partners (Foundation controlled)
//   TGE_VAULT            — Public liquidity, CEX listing (Deployer for testnet)
//
// GUARDIAN COUNCIL (5 seats, 4-of-5 veto):
//   On testnet all guardians = deployer for simplicity.
//   On mainnet: 5 independent entities, hardware-wallet controlled.
//
library SepoliaConfig {

    // ── Deployer ─────────────────────────────────────────────────────────────
    // Keypair từ passkey.txt [AXQ_DEPLOYER] — generated offline 03/09/2026
    // Set SEPOLIA_DEPLOYER_PK in GitHub Secrets (never commit the private key).
    // Address below must match vm.addr(SEPOLIA_DEPLOYER_PK) or deploy will revert.
    address internal constant DEPLOYER = 0xAf3D0febB24706912706660FB41D48Fc89548A53;

    // ── Vault addresses (testnet: dedicated wallets từ passkey.txt) ───────────
    // Mỗi vault có ví riêng — chuẩn bị cho mainnet migration
    // TODO-MAINNET: replace each with its real multisig before mainnet deploy
    address internal constant VPX_SUBSIDY_VAULT = DEPLOYER;                            // deployer (testnet)
    address internal constant RD_TREASURY_VAULT = 0x9B7AF512e3E5d2C27FFf9d53814883DAeca08AE4; // [ANS_TREASURY] (testnet treasury)
    address internal constant RWA_RESERVE_VAULT = DEPLOYER;                            // deployer (testnet)
    address internal constant STRATEGIC_VAULT   = DEPLOYER;                            // deployer (testnet)
    address internal constant TGE_VAULT         = DEPLOYER;                            // deployer (testnet)

    // ── Guardian Council — 3 ghế dùng ví riêng, 2 ghế deployer tạm ──────────
    // passkey.txt: [GUARDIAN_0], [GUARDIAN_1], [GUARDIAN_2]
    // TODO-MAINNET: 5 ghế độc lập với hardware wallet riêng biệt
    address internal constant GUARDIAN_0 = 0xAB8F9a9F3E3aFd97043E6b63D344d73535d1ce9F;
    address internal constant GUARDIAN_1 = 0x921ffd8ff806A281a760923Eb48997E4362c5cc3;
    address internal constant GUARDIAN_2 = 0xEd179Bbccd28D270b23811e2fBb042Db76c5A96B;
    address internal constant GUARDIAN_3 = DEPLOYER; // TODO: thêm ví thứ 4
    address internal constant GUARDIAN_4 = DEPLOYER; // TODO: thêm ví thứ 5

    // ── Output paths ──────────────────────────────────────────────────────────
    string internal constant ADDR_JSON   = "script/addresses-sepolia.json";
    string internal constant ENV_FILE    = ".env.sepolia";
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Deploy contracts (no genesis mint yet — requires ownership transfer)
// ─────────────────────────────────────────────────────────────────────────────
contract DeployAxqSepolia is Script {

    function run() external {
        uint256 deployerPk = vm.envUint("SEPOLIA_DEPLOYER_PK");
        address deployer   = vm.addr(deployerPk);

        require(deployer == SepoliaConfig.DEPLOYER, "DeployAxqSepolia: wrong deployer key");

        console.log("=== AXIOLEDGER SEPOLIA DEPLOY ===");
        console.log("Deployer:   ", deployer);
        console.log("Chain ID:   ", block.chainid);
        console.log("Balance:    ", deployer.balance / 1e15, "mETH");
        require(deployer.balance >= 0.02 ether, "DeployAxqSepolia: insufficient ETH, fund deployer first");

        vm.startBroadcast(deployerPk);

        uint256 deployerNonce = vm.getNonce(deployer);

        // Predict addresses using CREATE (nonce-based)
        address predictedToken = vm.computeCreateAddress(deployer, deployerNonce);
        address predictedVault = vm.computeCreateAddress(deployer, deployerNonce + 1);
        address predictedGov   = vm.computeCreateAddress(deployer, deployerNonce + 2);

        console.log("Predicted AXQToken:      ", predictedToken);
        console.log("Predicted VestingVault:  ", predictedVault);
        console.log("Predicted Governance:    ", predictedGov);

        // ── 1. Deploy AXQToken ────────────────────────────────────────────────
        // _dao = deployer (temp) so we can call genesisAllocate() in step 2.
        // Ownership is transferred to governance after genesis.
        AXQToken token = new AXQToken(
            SepoliaConfig.VPX_SUBSIDY_VAULT,  // vpxSubsidyVault
            SepoliaConfig.RD_TREASURY_VAULT,  // rdTreasuryVault
            SepoliaConfig.RWA_RESERVE_VAULT,  // rwaReserveVault
            predictedVault,                   // teamVestingVault (deployed next)
            SepoliaConfig.STRATEGIC_VAULT,    // strategicVault
            SepoliaConfig.TGE_VAULT,          // tgeVault
            deployer                          // _dao = deployer (temporary, transfer after genesis)
        );
        require(address(token) == predictedToken, "DeployAxqSepolia: token address mismatch");
        console.log("AXQToken deployed:       ", address(token));

        // ── 2. Deploy AXQVestingVault ─────────────────────────────────────────
        // _treasury = rdTreasury, _dao = predictedGov (governance will add/revoke grants)
        AXQVestingVault vault = new AXQVestingVault(
            address(token),
            SepoliaConfig.RD_TREASURY_VAULT,
            predictedGov
        );
        require(address(vault) == predictedVault, "DeployAxqSepolia: vault address mismatch");
        console.log("AXQVestingVault deployed:", address(vault));

        // ── 3. Deploy AXQGovernance ───────────────────────────────────────────
        address[5] memory guardians = [
            SepoliaConfig.GUARDIAN_0,
            SepoliaConfig.GUARDIAN_1,
            SepoliaConfig.GUARDIAN_2,
            SepoliaConfig.GUARDIAN_3,
            SepoliaConfig.GUARDIAN_4
        ];
        AXQGovernance governance = new AXQGovernance(
            address(token),
            SepoliaConfig.RD_TREASURY_VAULT,
            guardians
        );
        require(address(governance) == predictedGov, "DeployAxqSepolia: governance address mismatch");
        console.log("AXQGovernance deployed:  ", address(governance));

        vm.stopBroadcast();

        // Emit machine-parseable markers — printed to stdout for CI parsing
        // These are printed AFTER stopBroadcast so they appear in normal output,
        // not only in -vvv trace. Format: key=value on its own line.
        string memory outToken = string.concat("DEPLOY_OUTPUT_TOKEN=", vm.toString(address(token)));
        string memory outVault = string.concat("DEPLOY_OUTPUT_VESTING=", vm.toString(address(vault)));
        string memory outGov   = string.concat("DEPLOY_OUTPUT_GOVERNANCE=", vm.toString(address(governance)));
        console.log(outToken);
        console.log(outVault);
        console.log(outGov);

        // Best-effort file write (works locally; may be skipped in CI sandbox)
        try this._writeAddressJson(deployer, address(token), address(vault), address(governance)) {}
        catch { console.log("WARN: vm.writeFile skipped (CI sandbox)"); }
        try this._writeEnvFile(address(token), address(vault), address(governance)) {}
        catch { console.log("WARN: vm.writeEnvFile skipped (CI sandbox)"); }

        console.log("");
        console.log("=== DEPLOY COMPLETE - NEXT STEPS ===");
        console.log("1. Run DeployAxqSepoliaGenesis to call genesisAllocate()");
        console.log("2. Transfer token ownership to governance");
        console.log("3. Verify: forge verify-contract --chain sepolia --watch");
        console.log("4. Update identity-declaration.json with above addresses");
        console.log("=====================================");
    }

    function _writeAddressJson(
        address deployer,
        address token,
        address vault,
        address governance
    ) public {
        string memory nl = "\n";
        // Build JSON in two halves to stay within stack limit
        string memory part1 = string.concat(
            "{", nl,
            '  "network": "sepolia",', nl,
            '  "chainId": 11155111,', nl,
            '  "deployedAt": "', vm.toString(block.timestamp), '",', nl,
            '  "deployer": "', vm.toString(deployer), '",', nl,
            '  "contracts": {', nl,
            '    "axqToken":      "', vm.toString(token),      '",', nl,
            '    "axqVesting":    "', vm.toString(vault),      '",', nl,
            '    "axqGovernance": "', vm.toString(governance), '",', nl,
            '    "rdTreasury":    "', vm.toString(SepoliaConfig.RD_TREASURY_VAULT), '",', nl,
            '    "vpxSubsidy":    "', vm.toString(SepoliaConfig.VPX_SUBSIDY_VAULT), '",', nl,
            '    "rwaReserve":    "', vm.toString(SepoliaConfig.RWA_RESERVE_VAULT), '",', nl,
            '    "strategic":     "', vm.toString(SepoliaConfig.STRATEGIC_VAULT),   '",', nl,
            '    "tge":           "', vm.toString(SepoliaConfig.TGE_VAULT), '"', nl,
            '  }', nl,
            '}'
        );
        vm.writeFile(SepoliaConfig.ADDR_JSON, part1);
        console.log("addresses-sepolia.json written to:", SepoliaConfig.ADDR_JSON);
    }

    function _writeEnvFile(
        address token,
        address vault,
        address governance
    ) public {
        string memory nl = "\n";
        string memory envContent = string.concat(
            "# AXIOLEDGER Sepolia Testnet - auto-generated by DeployAxqSepolia", nl,
            "# DO NOT COMMIT - set SEPOLIA_RPC_URL and private keys via CI secrets", nl,
            nl,
            "NEXT_PUBLIC_NETWORK=sepolia", nl,
            "NEXT_PUBLIC_RPC_URL=${SEPOLIA_RPC_URL}", nl,
            "NEXT_PUBLIC_CHAIN_ID=11155111", nl,
            nl,
            "NEXT_PUBLIC_AXQ_TOKEN=",      vm.toString(token),      nl,
            "NEXT_PUBLIC_AXQ_VESTING=",    vm.toString(vault),      nl,
            "NEXT_PUBLIC_AXQ_GOVERNANCE=", vm.toString(governance), nl,
            "NEXT_PUBLIC_RD_TREASURY=",    vm.toString(SepoliaConfig.RD_TREASURY_VAULT), nl,
            nl,
            "# KPX + ANS (fill in after Sepolia deploy of those contracts)", nl,
            "NEXT_PUBLIC_KPX_ROUTER=", nl,
            "NEXT_PUBLIC_ANS_REGISTRY=", nl,
            nl,
            "# Treasury sweep (set private key via secret manager - never commit)", nl,
            "AXQ_TOKEN_ADDRESS=",  vm.toString(token), nl,
            "SWEEP_TARGET=",       vm.toString(SepoliaConfig.RD_TREASURY_VAULT), nl,
            "AXQ_RPC_URL=${SEPOLIA_RPC_URL}", nl,
            "# SEPOLIA_DEPLOYER_PK= <-- inject via CI/CD secret, never hardcode", nl
        );
        vm.writeFile(SepoliaConfig.ENV_FILE, envContent);
        console.log(".env.sepolia template written to:", SepoliaConfig.ENV_FILE);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Genesis — mint 500B AXQ + self-delegate deployer for governance
// Run AFTER DeployAxqSepolia, reads from addresses-sepolia.json
// ─────────────────────────────────────────────────────────────────────────────
contract DeployAxqSepoliaGenesis is Script {

    function run() external {
        uint256 deployerPk = vm.envUint("SEPOLIA_DEPLOYER_PK");
        address deployer   = vm.addr(deployerPk);

        require(deployer == SepoliaConfig.DEPLOYER, "SepoliaGenesis: wrong deployer key");

        // Read addresses from env vars (set by CI from deploy-axq outputs)
        // Fallback to JSON file for local runs
        address tokenAddr;
        address govAddr;
        try vm.envAddress("AXQ_TOKEN") returns (address t) {
            tokenAddr = t;
        } catch {
            string memory jsonData = vm.readFile(SepoliaConfig.ADDR_JSON);
            tokenAddr = abi.decode(vm.parseJson(jsonData, ".contracts.axqToken"), (address));
        }
        try vm.envAddress("AXQ_GOVERNANCE") returns (address g) {
            govAddr = g;
        } catch {
            string memory jsonData = vm.readFile(SepoliaConfig.ADDR_JSON);
            govAddr = abi.decode(vm.parseJson(jsonData, ".contracts.axqGovernance"), (address));
        }
        require(tokenAddr != address(0), "SepoliaGenesis: AXQ_TOKEN not set");
        require(govAddr   != address(0), "SepoliaGenesis: AXQ_GOVERNANCE not set");

        console.log("=== AXIOLEDGER SEPOLIA GENESIS ===");
        console.log("AXQToken:   ", tokenAddr);
        console.log("Governance: ", govAddr);

        vm.startBroadcast(deployerPk);

        AXQToken token = AXQToken(tokenAddr);

        // Mint 500B AXQ across all vaults (deployer is temporary owner)
        token.genesisAllocate();
        console.log("genesisAllocate() called - 500B AXQ minted");

        // Self-delegate deployer's AXQ so it has immediate voting power
        token.delegate(deployer);
        console.log("Deployer self-delegated voting power");

        // Initiate ownership transfer to governance (2-step: deployer initiates)
        // governance must call acceptOwnership() via a proposal (Ownable2Step)
        token.transferOwnership(govAddr);
        console.log("transferOwnership(governance) initiated - awaiting acceptOwnership()");

        vm.stopBroadcast();

        console.log("");
        console.log("=== GENESIS COMPLETE ===");
        console.log("- 500B AXQ minted and distributed");
        console.log("- Deployer has voting power (self-delegated)");
        console.log("- Ownership transfer pending: governance must call acceptOwnership()");
        console.log("  via a DAO proposal or directly if deployer is also a guardian.");
        console.log("========================");
    }
}
