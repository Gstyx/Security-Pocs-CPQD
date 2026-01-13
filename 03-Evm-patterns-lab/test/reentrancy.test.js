const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy demo", function () {
  it("should be drained by attacker (vulnerable) ", async function () {
    const [owner, attacker] = await ethers.getSigners();

    const Vault = await ethers.getContractFactory("VulnerableVault");
    const vault = await Vault.deploy();
    await vault.waitForDeployment();

    const ReentrancyAttacker = await ethers.getContractFactory("ReentrancyAttacker");
    const att = await ReentrancyAttacker.connect(attacker).deploy(vault.target);
    await att.waitForDeployment();

    // Attacker funds its contract
    await attacker.sendTransaction({ to: att.target, value: ethers.parseEther("1") });

    // Attacker triggers
    await att.connect(attacker).attack({ gasLimit: 3_000_000 });

    expect(await ethers.provider.getBalance(vault.target)).to.equal(0);
  });
});
