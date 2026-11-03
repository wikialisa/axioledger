import { ethers } from "hardhat";
import fs from "fs";
import path from "path";

// ─── 01-deploy-kernel.ts ──────────────────────────────────────────────────────
// Bước 1: Deploy tokens + Kernel.
// ─────────────────────────────────────────────────────────────────────────────

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = (await ethers.provider.getNetwork()).name;
  console.log(`\n🚀  [01] Deploy Kernel — deployer: ${deployer.address}  network: ${network}\n`);

  const YOUR_TOKEN = await (await ethers.getContractFactory("YOUR_TOKENToken")).deploy(deployer.address);
  await YOUR_TOKEN.waitForDeployment();
  console.log(`  ✅ YOUR_TOKENToken   → ${await YOUR_TOKEN.getAddress()}`);

  const sAXVN = await (await ethers.getContractFactory("SYOUR_TOKENToken")).deploy(deployer.address);
  await sAXVN.waitForDeployment();
  console.log(`  ✅ sYOUR_TOKENToken  → ${await sAXVN.getAddress()}`);

  const gAXVN = await (await ethers.getContractFactory("GYOUR_TOKENToken")).deploy(deployer.address);
  await gAXVN.waitForDeployment();
  console.log(`  ✅ gYOUR_TOKENToken  → ${await gAXVN.getAddress()}`);

  const kernel = await (await ethers.getContractFactory("Kernel")).deploy(deployer.address, deployer.address);
  await kernel.waitForDeployment();
  console.log(`  ✅ Kernel      → ${await kernel.getAddress()}`);

  _save(network, {
    YOUR_TOKEN_TOKEN: await YOUR_TOKEN.getAddress(),
    SAXVN_TOKEN: await sAXVN.getAddress(),
    GAXVN_TOKEN: await gAXVN.getAddress(),
    KERNEL: await kernel.getAddress(),
  });
}

function _save(network: string, patch: Record<string, string>) {
  const p = path.resolve(__dirname, "../exports/addresses.json");
  const data: Record<string, Record<string, string>> = fs.existsSync(p)
    ? JSON.parse(fs.readFileSync(p, "utf-8")) : {};
  data[network] = { ...(data[network] ?? {}), ...patch };
  fs.writeFileSync(p, JSON.stringify(data, null, 2));
  console.log(`\n  📄 addresses.json updated\n`);
}

main().catch((e) => { console.error(e); process.exit(1); });
