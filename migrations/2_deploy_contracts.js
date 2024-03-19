const TraveldqToken = artifacts.require("TraveldqToken");
const USDC = artifacts.require("./usdc.sol");

module.exports = async (deployer) => {
  await deployer.deploy(USDC, {gas: 6721975});
  const usdc = await USDC.deployed();

  await deployer.deploy(TraveldqToken, USDC.address, {gas: 6721975});

  console.log("usdc address: %s", USDC.address);
  console.log("TraveldqToken address: %s", TraveldqToken.address);
};
