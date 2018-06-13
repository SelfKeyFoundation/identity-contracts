const Identity = artifacts.require("./Identity.sol")
const IdentityFactory = artifacts.require("./IdentityFactory.sol")
const ERC20Mock = artifacts.require("../test/mock/ERC20Mock.sol")

const assertThrows = require("./utils/assertThrows")
const { getLog } = require("./utils/txHelpers")
//const keccak256 = require('keccak')

const MANAGEMENT_KEY = 1
const ACTION_KEY = 2
const CLAIM_SIGNER_KEY = 3
const ENCRYPTION_KEY = 4

const ETH_ADDR = 1
const RSA = 2
const ECDSA = 3
const OTHER = 4

contract("Identity", accounts => {
  const [owner, user1, user2, user3, user4, user5] = accounts.slice(0)
  let factoryContract
  let identity

  before(async () => {
    // instantiate factory contract
    factoryContract = await IdentityFactory.new()
    assert.isNotNull(factoryContract)

    // create new identity through factory contract
    const tx = await factoryContract.createIdentity()
    const log = getLog(tx, "IdentityCreated")
    identity = Identity.at(log.args["idContract"])
  })

  context("Key management", () => {
    it("deploys successfully through factory contract", async () => {
      assert.isNotNull(identity)
    })

    it("adds key only if sender has manager role", async () => {
      // Adds a second "manager"
      await identity.addAddressAsKey(user2, MANAGEMENT_KEY, ETH_ADDR)
      let added = await identity.addressHasPurpose(user2, MANAGEMENT_KEY)
      assert.isTrue(added)

      // New manager is able to add more keys. Adds user3 as an ACTION_KEY
      await identity.addAddressAsKey(user3, ACTION_KEY, ETH_ADDR, {
        from: user2
      })
      added = await identity.addressHasPurpose(user3, ACTION_KEY)
      assert.isTrue(added)

      // Add arbitrary key
      await identity.addKey("THIS-IS-A-KEY", ACTION_KEY, OTHER, { from: user2 })
      added = await identity.keyHasPurpose("THIS-IS-A-KEY", ACTION_KEY)
      assert.isTrue(added)

      // Fails adding a key that already exists
      await assertThrows(
        identity.addKey("THIS-IS-A-KEY", ACTION_KEY, OTHER, { from: user2 })
      )

      // Fails to add a key if caller has no management key (user3 has only ACTION_KEY)
      await assertThrows(
        identity.addAddressAsKey(user4, ACTION_KEY, ETH_ADDR, { from: user3 })
      )
    })

    it("retrieves a specific key successfully", async () => {
      let key = await identity.getKeyByAddress(user2)
      //assert.equal(key[0], user2)   // NEEDS KECCAK HASH
      key = await identity.getKeyByAddress(user3)
      //assert.equal(key[0], user3)
    })

    it("can retrieve all added keys", async () => {
      let keysCount = await identity.keysCount.call()
      assert.equal(Number(keysCount), 4)

      let key, hash
      for (var i = 0; i < keysCount; i++) {
        hash = await identity.keyIndexes.call(i)
        key = await identity.getKey(hash)

        // check the first position of each key corresponds to a valid ethereum address
        assert.isNotNull(key[0].match(/0x[0-9a-fA-F]{40}/))
        //console.log(key[0] + " => " + Number(key[1]))
      }
    })

    it("cannot retrieve a non-existing key", async () => {
      await assertThrows(identity.getKey("FOOBAR-DOESNOTEXIST"))
    })

    it("removes key only if sender has manager role", async () => {
      // Checks key exists first
      let deleteKey = await identity.getKeyByAddress(user2)

      // Original owner removes key
      let tx = await identity.removeKey(deleteKey[0], { from: owner })

      // Checks key was effectively removed
      await assertThrows(identity.getKeyByAddress(user2))

      // check the key counter and key indexing structures are correct
      const keysCount = await identity.keysCount.call()
      assert.equal(Number(keysCount), 3)

      let remainingKey, hash
      for (var i = 0; i < keysCount; i++) {
        hash = await identity.keyIndexes.call(i)
        remainingKey = await identity.getKey(hash)
        // check the deleted key was effectively deleted
        assert.notEqual(remainingKey[0], deleteKey[0])
      }

      // Cannot remove a key that does not exist
      await assertThrows(identity.removeKey("THISISNOTAKEY"))
    })
  })

  context("Service Endpoints", () => {
    it("adds and retrieves new service endpoints", async () => {
      const serviceEndpoint =
        "https://hub.example.com/.identity/did:key:01234567abcdef/"
      const serviceType = "HubService"
      await identity.addService(serviceType, serviceEndpoint)
      const gotService = await identity.getServiceByType(serviceType)
      assert.equal(gotService, serviceEndpoint)

      // add a second service endpoint, because why not?
      const serviceEndpoint2 = "https://example.com/messages/8377464"
      const serviceType2 = "MessagingService"
      await identity.addService(serviceType2, serviceEndpoint2)
      const gotService2 = await identity.getServiceByType(serviceType2)
      assert.equal(gotService2, serviceEndpoint2)

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 2)
    })

    it("fails to add services from a non manager address", async () => {
      const serviceEndpoint =
        "https://xdi.example.com/.identity/did:key:01234567abcdef/"
      const serviceType = "XDIService"
      const hasPurpose = await identity.addressHasPurpose(user3, MANAGEMENT_KEY)
      assert.isFalse(hasPurpose)
      await assertThrows(
        identity.addService(serviceType, serviceEndpoint, { from: user3 })
      )
    })

    it("updates existing service endpoint", async () => {
      const serviceEndpoint =
        "https://hub.example.com/.identity/did:key:9876432cdefajj/"
      const serviceType = "HubService"
      await identity.addService(serviceType, serviceEndpoint)
      const gotService = await identity.getServiceByType(serviceType)
      assert.equal(gotService, serviceEndpoint)

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 2)
    })

    it("fails to update services from a non manager address", async () => {
      const serviceEndpoint =
        "https://hub.attacker.com/.identity/did:key:01234567abcdef/"
      const serviceType = "HubService"
      await assertThrows(
        identity.addService(serviceType, serviceEndpoint, { from: user2 })
      )
    })

    it("removes existing service endpoint", async () => {
      const serviceType = "HubService"
      await identity.removeService(serviceType)
      await assertThrows(identity.getServiceByType(serviceType))

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 1)
    })

    it("fails to remove existing service endpoint if caller is not a manager", async () => {
      const serviceType = "MessagingService"
      await assertThrows(identity.removeService(serviceType, { from: user2 }))

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 1)
    })
  })

  context("Handling ETH and assets", () => {
    let token

    before(async () => {
      const sendAmountEth = web3.toWei(2, "ether")
      const sendAmountToken = 2000

      // send ETH to the identity contract
      await identity.sendTransaction({
        from: user1,
        value: sendAmountEth
      })
      const balance = Number(web3.eth.getBalance(identity.address))
      assert(balance, sendAmountEth)

      //send ERC20 token to the identity contract
      token = await ERC20Mock.new()
      await token.transfer(identity.address, sendAmountToken, { from: owner })
      const tokenBalance = await token.balanceOf.call(identity.address)
      assert.equal(Number(tokenBalance), sendAmountToken)
    })

    it("allows withdrawal of ETH by a manager", async () => {
      const ownerBalance1 = Number(web3.eth.getBalance(owner))
      const contractBalance1 = Number(web3.eth.getBalance(identity.address))
      await identity.withdrawEth(web3.toWei(1, "ether"), { from: owner })
      const ownerBalance2 = Number(web3.eth.getBalance(owner))
      const contractBalance2 = Number(web3.eth.getBalance(identity.address))

      assert.isAbove(ownerBalance2, ownerBalance1)
      assert.isBelow(contractBalance2, contractBalance1)
    })

    it("allows withdrawal of ERC20 tokens by a manager", async () => {
      const withdrawAmount = 1000

      const ownerBalance1 = await token.balanceOf.call(owner)
      const contractBalance1 = await token.balanceOf.call(identity.address)
      await identity.withdrawERC20(withdrawAmount, token.address, {
        from: owner
      })
      const ownerBalance2 = await token.balanceOf.call(owner)
      const contractBalance2 = await token.balanceOf.call(identity.address)

      assert.isAbove(Number(ownerBalance2), Number(ownerBalance1))
      assert.isBelow(Number(contractBalance2), Number(contractBalance1))
    })
  })
})
