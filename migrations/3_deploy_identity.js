const Identity = artifacts.require('./Identity.sol')

const ownerAddress = '0x42AA3D8a40C9Bd501f92617a280a539f3Cb6957A'

module.exports = deployer => {
  deployer.deploy(Identity, ownerAddress)
}
