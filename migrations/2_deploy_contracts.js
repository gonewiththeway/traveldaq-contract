const AirlineTicket = artifacts.require("TraveldqToken");
const USDC = artifacts.require("./usdc.sol");

module.exports = async (deployer) => {
  await deployer.deploy(USDC, {gas: 6721975});
    // .then(() => console.log(USDC.address))
    // .then(() => deployer.deploy(AirlineTicket, USDC.address))
    // .then(() => console.log(AirlineTicket.address))
};
