const IdentityFactory = artifacts.require('./IdentityFactory.sol')

module.exports = deployer => {
  deployer.deploy(IdentityFactory)
}
