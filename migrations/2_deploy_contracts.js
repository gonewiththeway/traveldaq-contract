const AirlineTicket = artifacts.require("AirlineTicket");

module.exports = function (deployer) {
  deployer.deploy(AirlineTicket, "<USDC_CONTRACT_ADDRESS>");
};
