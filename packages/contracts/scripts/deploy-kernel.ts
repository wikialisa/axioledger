import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

// ─── deploy-kernel.ts ─────────────────────────────────────────────────────────
// Deploy AXVNToken + Kernel, then save addresses to exports/addresses.json.
// Run: hardhat run scripts/deploy-kernel.ts --network <network>
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`\n🚀  Deploying Kernel — deployer: ${deployer.address}`);
  console.log(`    Network: ${(await ethers.provider.getNetwork()).name}\n`);

  // ── 1. Deploy AXVN token ────────────────────────────────────────────────
  const AXVNToken = await ethers.getContractFactory("AXVNToken");
  const AXVN = await AXVNToken.deploy(deployer.address);
  await AXVN.waitForDeployment();
  console.log(`  ✅ AXVNToken    → ${await AXVN.getAddress()}`);

  // ── 2. Deploy sAXVN token ───────────────────────────────────────────────
  const SAXVNToken = await ethers.getContractFactory("SAXVNToken");
  const sAXVN = await SAXVNToken.deploy(deployer.address);
  await sAXVN.waitForDeployment();
  console.log(`  ✅ SAXVNToken   → ${await sAXVN.getAddress()}`);

  // ── 3. Deploy gAXVN token ───────────────────────────────────────────────
  const GAXVNToken = await ethers.getContractFactory("GAXVNToken");
  const gAXVN = await GAXVNToken.deploy(deployer.address);
  await gAXVN.waitForDeployment();
  console.log(`  ✅ GAXVNToken   → ${await gAXVN.getAddress()}`);

  // ── 4. Deploy Kernel ────────────────────────────────────────────────────
  const Kernel = await ethers.getContractFactory("Kernel");
  const kernel = await Kernel.deploy(deployer.address, deployer.address);
  await kernel.waitForDeployment();
  console.log(`  ✅ Kernel       → ${await kernel.getAddress()}`);

  // ── 5. Persist addresses ────────────────────────────────────────────────
  const network = (await ethers.provider.getNetwork()).name;
  const outPath = path.resolve(__dirname, "../exports/addresses.json");
  let existing: Record<string, Record<string, string>> = {};
  if (fs.existsSync(outPath)) {
    existing = JSON.parse(fs.readFileSync(outPath, "utf-8"));
  }

  existing[network] = {
    ...(existing[network] ?? {}),
    AXVN_TOKEN: await AXVN.getAddress(),
    SAXVN_TOKEN: await sAXVN.getAddress(),
    GAXVN_TOKEN: await gAXVN.getAddress(),
    KERNEL: await kernel.getAddress(),
  };

  fs.writeFileSync(outPath, JSON.stringify(existing, null, 2));
  console.log(`\n  📄 Addresses saved → exports/addresses.json\n`);
}

main().catch((err) => { console.error(err); process.exit(1); });
