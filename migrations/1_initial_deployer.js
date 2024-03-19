const Migrations = artifacts.require("./ContractDeployer.sol")

module.exports = function(deployer) {
  deployer.deploy(Migrations)
}
