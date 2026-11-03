import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

// ─── deploy-kernel.ts ─────────────────────────────────────────────────────────
// Deploy YOUR_TOKENToken + Kernel, then save addresses to exports/addresses.json.
// Run: hardhat run scripts/deploy-kernel.ts --network <network>
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`\n🚀  Deploying Kernel — deployer: ${deployer.address}`);
  console.log(`    Network: ${(await ethers.provider.getNetwork()).name}\n`);

  // ── 1. Deploy YOUR_TOKEN token ────────────────────────────────────────────────
  const YOUR_TOKENToken = await ethers.getContractFactory("YOUR_TOKENToken");
  const YOUR_TOKEN = await YOUR_TOKENToken.deploy(deployer.address);
  await YOUR_TOKEN.waitForDeployment();
  console.log(`  ✅ YOUR_TOKENToken    → ${await YOUR_TOKEN.getAddress()}`);

  // ── 2. Deploy sAXVN token ───────────────────────────────────────────────
  const SYOUR_TOKENToken = await ethers.getContractFactory("SYOUR_TOKENToken");
  const sAXVN = await SYOUR_TOKENToken.deploy(deployer.address);
  await sAXVN.waitForDeployment();
  console.log(`  ✅ SYOUR_TOKENToken   → ${await sAXVN.getAddress()}`);

  // ── 3. Deploy gAXVN token ───────────────────────────────────────────────
  const GYOUR_TOKENToken = await ethers.getContractFactory("GYOUR_TOKENToken");
  const gAXVN = await GYOUR_TOKENToken.deploy(deployer.address);
  await gAXVN.waitForDeployment();
  console.log(`  ✅ GYOUR_TOKENToken   → ${await gAXVN.getAddress()}`);

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
    YOUR_TOKEN_TOKEN: await YOUR_TOKEN.getAddress(),
    SAXVN_TOKEN: await sAXVN.getAddress(),
    GAXVN_TOKEN: await gAXVN.getAddress(),
    KERNEL: await kernel.getAddress(),
  };

  fs.writeFileSync(outPath, JSON.stringify(existing, null, 2));
  console.log(`\n  📄 Addresses saved → exports/addresses.json\n`);
}

main().catch((err) => { console.error(err); process.exit(1); });
