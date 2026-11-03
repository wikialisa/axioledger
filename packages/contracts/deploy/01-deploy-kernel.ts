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

  const AXVN = await (await ethers.getContractFactory("AXVNToken")).deploy(deployer.address);
  await AXVN.waitForDeployment();
  console.log(`  ✅ AXVNToken   → ${await AXVN.getAddress()}`);

  const sAXVN = await (await ethers.getContractFactory("SAXVNToken")).deploy(deployer.address);
  await sAXVN.waitForDeployment();
  console.log(`  ✅ sAXVNToken  → ${await sAXVN.getAddress()}`);

  const gAXVN = await (await ethers.getContractFactory("GAXVNToken")).deploy(deployer.address);
  await gAXVN.waitForDeployment();
  console.log(`  ✅ gAXVNToken  → ${await gAXVN.getAddress()}`);

  const kernel = await (await ethers.getContractFactory("Kernel")).deploy(deployer.address, deployer.address);
  await kernel.waitForDeployment();
  console.log(`  ✅ Kernel      → ${await kernel.getAddress()}`);

  _save(network, {
    AXVN_TOKEN: await AXVN.getAddress(),
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
