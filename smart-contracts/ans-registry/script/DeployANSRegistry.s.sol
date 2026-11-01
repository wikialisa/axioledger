// SPDX-License-Identifier: MIT
// AXIOLEDGER — ANS Registry Deployment Script
//
// Usage - Anvil localnet:
//   forge script script/DeployANSRegistry.s.sol:DeployANSRegistry \
//     --rpc-url http://127.0.0.1:8545 \
//     --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
//     --broadcast -vvvv
//
// Usage - Sepolia:
//   forge script script/DeployANSRegistry.s.sol:DeployANSRegistry \
//     --rpc-url $SEPOLIA_RPC_URL \
//     --private-key $DEPLOYER_PRIVATE_KEY \
//     --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
//
// Constructor: ANSRegistry(address _treasury, address _dao)
//   _treasury — receives registration fees (ETH)
//   _dao      — Ownable2Step owner; controls TLDs, fees, name locks

pragma solidity ^0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/ANSRegistry.sol";

contract DeployANSRegistry is Script {

    // Canonical chain IDs
    uint256 constant CHAIN_ANVIL   = 31337;
    uint256 constant CHAIN_SEPOLIA = 11155111;
    uint256 constant CHAIN_MAINNET = 1;

    // Localnet addresses from axioledger-system deployment (addresses.json)
    address constant LOCALNET_TREASURY     = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC; // rdTreasury
    address constant LOCALNET_GOVERNANCE   = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0; // AXQGovernance

    function run() external {
        uint256 deployerKey = vm.envOr(
            "DEPLOYER_PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        address deployer = vm.addr(deployerKey);

        console.log("=================================================");
        console.log("  AXIOLEDGER Name Service (ANS) -- Deployment");
        console.log("=================================================");
        console.log("Chain ID  :", block.chainid);
        console.log("Deployer  :", deployer);
        console.log("");

        // Resolve treasury and DAO addresses per network
        address treasury;
        address dao;

        if (block.chainid == CHAIN_ANVIL) {
            // Localnet: use deployed axioledger-system addresses
            treasury = LOCALNET_TREASURY;
            dao      = LOCALNET_GOVERNANCE;
            console.log("Network   : LOCALNET (Anvil)");
        } else {
            // Staging / production: require env vars
            treasury = vm.envAddress("ANS_TREASURY_ADDRESS");
            dao      = vm.envAddress("ANS_DAO_ADDRESS");
            console.log("Network   : EXTERNAL");
        }

        if (block.chainid == CHAIN_MAINNET) {
            require(dao != deployer, "MAINNET: DAO must be a governance multisig, not the deployer EOA");
        }

        console.log("Treasury  :", treasury);
        console.log("DAO       :", dao);
        console.log("");

        vm.startBroadcast(deployerKey);

        ANSRegistry registry = new ANSRegistry(treasury, dao);

        vm.stopBroadcast();

        console.log("=================================================");
        console.log("  ANS DEPLOYED ADDRESSES");
        console.log("=================================================");
        console.log("ANSRegistry :", address(registry));
        console.log("Treasury    :", treasury);
        console.log("DAO (Owner) :", dao);
        console.log("=================================================");
        console.log("");
        console.log("Supported TLDs (fee = 0.01 ETH each):");
        console.log("  .axq  .vpx  .sqx  .kpx  .vrq");
        console.log("=================================================");

        // Write addresses to script/ans-addresses.json for downstream consumption
        string memory json = string(abi.encodePacked(
            '{"network":"localnet","chainId":',
            vm.toString(block.chainid),
            ',"contracts":{"ansRegistry":"',
            vm.toString(address(registry)),
            '","treasury":"',
            vm.toString(treasury),
            '","dao":"',
            vm.toString(dao),
            '"}}'
        ));
        vm.writeFile("script/ans-addresses.json", json);
        console.log("[written] script/ans-addresses.json");
    }
}
