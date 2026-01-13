// scripts/deploy_all.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const Vault = await hre.ethers.getContractFactory("VulnerableVault");
  const vault = await Vault.deploy();
  await vault.waitForDeployment();
  console.log("VulnerableVault at", vault.target);

  const Bad = await hre.ethers.getContractFactory("BadAccessControl");
  const bad = await Bad.deploy();
  await bad.waitForDeployment();
  console.log("BadAccessControl at", bad.target);

  const Logic = await hre.ethers.getContractFactory("LogicV1");
  const logic = await Logic.deploy();
  await logic.waitForDeployment();
  console.log("LogicV1 at", logic.target);

  const Proxy = await hre.ethers.getContractFactory("Proxy");
  const proxy = await Proxy.deploy(logic.target);
  await proxy.waitForDeployment();
  console.log("Proxy at", proxy.target);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
