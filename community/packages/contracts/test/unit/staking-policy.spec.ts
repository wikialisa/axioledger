import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";

// ─── staking-policy.spec.ts ───────────────────────────────────────────────────
// Unit tests for StakingPolicy: stake, unstake, wrap, unwrap, rebase.
// ─────────────────────────────────────────────────────────────────────────────

describe("StakingPolicy", () => {
  let deployer: Signer;
  let alice: Signer;

  let kernel: Awaited<ReturnType<typeof ethers.getContractAt>>;
  let YOUR_TOKEN: Awaited<ReturnType<typeof ethers.getContractAt>>;
  let sAXVN: Awaited<ReturnType<typeof ethers.getContractAt>>;
  let gAXVN: Awaited<ReturnType<typeof ethers.getContractAt>>;
  let mintr: Awaited<ReturnType<typeof ethers.getContractAt>>;
  let staking: Awaited<ReturnType<typeof ethers.getContractAt>>;

  const Actions = { InstallModule: 0, ActivatePolicy: 2 };
  const STAKE_AMOUNT = ethers.parseUnits("1000", 18);

  beforeEach(async () => {
    [deployer, alice] = await ethers.getSigners();

    // Deploy tokens
    const YOUR_TOKENToken = await ethers.getContractFactory("YOUR_TOKENToken");
    const SYOUR_TOKENToken = await ethers.getContractFactory("SYOUR_TOKENToken");
    const GYOUR_TOKENToken = await ethers.getContractFactory("GYOUR_TOKENToken");
    YOUR_TOKEN = await (await YOUR_TOKENToken.deploy(await deployer.getAddress())).waitForDeployment();
    sAXVN = await (await SYOUR_TOKENToken.deploy(await deployer.getAddress())).waitForDeployment();
    gAXVN = await (await GYOUR_TOKENToken.deploy(await deployer.getAddress())).waitForDeployment();

    // Deploy kernel
    const Kernel = await ethers.getContractFactory("Kernel");
    kernel = await (await Kernel.deploy(
      await deployer.getAddress(),
      await deployer.getAddress()
    )).waitForDeployment();

    // Deploy + install MINTRv1
    const MINTRv1 = await ethers.getContractFactory("MINTRv1");
    mintr = await (await MINTRv1.deploy(
      await kernel.getAddress(),
      await YOUR_TOKEN.getAddress()
    )).waitForDeployment();
    await (kernel as any).executeAction(Actions.InstallModule, await mintr.getAddress());
    await (YOUR_TOKEN as any).setMintAuthority(await mintr.getAddress());

    // Deploy + activate StakingPolicy
    const StakingPolicy = await ethers.getContractFactory("StakingPolicy");
    staking = await (await StakingPolicy.deploy(
      await kernel.getAddress(),
      await YOUR_TOKEN.getAddress(),
      await sYOUR_TOKEN.getAddress(),
      await gYOUR_TOKEN.getAddress()
    )).waitForDeployment();
    await (kernel as any).executeAction(Actions.ActivatePolicy, await staking.getAddress());
    await (sYOUR_TOKEN as any).setStakingPolicy(await staking.getAddress());
    await (gYOUR_TOKEN as any).setStakingPolicy(await staking.getAddress());

    // Mint YOUR_TOKEN to alice for testing (deployer is still mint authority)
    await (YOUR_TOKEN as any).setMintAuthority(await deployer.getAddress());
    await (YOUR_TOKEN as any).mint(await alice.getAddress(), ethers.parseUnits("10000", 18));
    await (YOUR_TOKEN as any).setMintAuthority(await mintr.getAddress());
  });

  it("should stake YOUR_TOKEN and receive sAXVN 1:1", async () => {
    await (YOUR_TOKEN as any).connect(alice).approve(await staking.getAddress(), STAKE_AMOUNT);
    await (staking as any).connect(alice).stake(STAKE_AMOUNT);

    expect(await (sAXVN as any).balanceOf(await alice.getAddress())).to.equal(STAKE_AMOUNT);
  });

  it("should unstake sYOUR_TOKEN and return YOUR_TOKEN", async () => {
    await (YOUR_TOKEN as any).connect(alice).approve(await staking.getAddress(), STAKE_AMOUNT);
    await (staking as any).connect(alice).stake(STAKE_AMOUNT);
    await (staking as any).connect(alice).unstake(STAKE_AMOUNT);

    expect(await (sAXVN as any).balanceOf(await alice.getAddress())).to.equal(0n);
  });

  it("should wrap sAXVN → gAXVN and unwrap back", async () => {
    await (YOUR_TOKEN as any).connect(alice).approve(await staking.getAddress(), STAKE_AMOUNT);
    await (staking as any).connect(alice).stake(STAKE_AMOUNT);
    await (staking as any).connect(alice).wrap(STAKE_AMOUNT);

    expect(await (gAXVN as any).balanceOf(await alice.getAddress())).to.equal(STAKE_AMOUNT);
    expect(await (sAXVN as any).balanceOf(await alice.getAddress())).to.equal(0n);

    await (staking as any).connect(alice).unwrap(STAKE_AMOUNT);
    expect(await (sAXVN as any).balanceOf(await alice.getAddress())).to.equal(STAKE_AMOUNT);
  });

  it("should revert unstake if insufficient staked balance", async () => {
    await expect((staking as any).connect(alice).unstake(STAKE_AMOUNT))
      .to.be.revertedWithCustomError(staking, "Staking_NotEnoughStaked");
  });

  it("should revert stake of zero amount", async () => {
    await expect((staking as any).connect(alice).stake(0n))
      .to.be.revertedWithCustomError(staking, "Staking_InvalidAmount");
  });
});
