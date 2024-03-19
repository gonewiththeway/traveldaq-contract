const USDC = artifacts.require("usdc.sol");

contract("USDC", (accounts) => {
  let usdc;
  const [owner, addr1, addr2] = accounts;

  beforeEach(async () => {
    usdc = await USDC.new();
  });

  it("Should transfer tokens between accounts", async () => {
    // Transfer 50 tokens from owner to addr1
    await usdc.transfer(addr1, 50, { from: owner });
    const addr1Balance = await usdc.balanceOf(addr1);
    assert.equal(addr1Balance.toNumber(), 50, "addr1 did not receive the tokens");

    // Transfer 50 tokens from addr1 to addr2
    await usdc.transfer(addr2, 50, { from: addr1 });
    const addr2Balance = await usdc.balanceOf(addr2);
    assert.equal(addr2Balance.toNumber(), 50, "addr2 did not receive the tokens");
  });
});
