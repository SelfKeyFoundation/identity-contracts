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
  let token
  let executionRequest

  before(async () => {
    // instantiate factory contract
    token = await ERC20Mock.new()
    factoryContract = await IdentityFactory.new()
    assert.isNotNull(factoryContract)
    assert.isNotNull(token)

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
      key = await identity.getKeyByAddress(user3)
      // if it doesn't throw error, then the key exists
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
      // fails to remove a non-existing service
      await assertThrows(identity.removeService("Monger"))

      const serviceType = "HubService"
      await identity.removeService(serviceType)
      const endpoint = await identity.getServiceByType(serviceType)
      assert.equal(endpoint, "")

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
    before(async () => {
      const sendAmountEth = web3.toWei(2, "ether")
      const sendAmountToken = 2000

      let tx = await identity.sendTransaction({
        from: user1,
        value: 0
      })
      let foundEvent = tx.logs.find(log => log.event === "ReceivedETH")
      assert.isUndefined(foundEvent)

      // send ETH to the identity contract
      tx = await identity.sendTransaction({
        from: user1,
        value: sendAmountEth
      })
      const log = getLog(tx, "ReceivedETH")

      // check balances changed accordingly
      const balance = Number(web3.eth.getBalance(identity.address))
      assert(balance, sendAmountEth)

      await token.transfer(identity.address, sendAmountToken, { from: owner })
      const tokenBalance = await token.balanceOf.call(identity.address)
      assert.equal(Number(tokenBalance), sendAmountToken)
    })

    it("allows withdrawal of ETH by a manager", async () => {
      const ownerBalance1 = Number(web3.eth.getBalance(owner))
      const contractBalance1 = Number(web3.eth.getBalance(identity.address))

      // withdrawing more than actual balance fails
      await assertThrows(
        identity.withdrawEth(web3.toWei(999999, "ether"), { from: owner })
      )

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

      // withdrawing more tokens than actual balance fails
      await assertThrows(
        identity.withdrawERC20(999999, token.address, { from: owner })
      )

      await identity.withdrawERC20(withdrawAmount, token.address, {
        from: owner
      })
      const ownerBalance2 = await token.balanceOf.call(owner)
      const contractBalance2 = await token.balanceOf.call(identity.address)

      assert.isAbove(Number(ownerBalance2), Number(ownerBalance1))
      assert.isBelow(Number(contractBalance2), Number(contractBalance1))
      assert.equal(Number(contractBalance2), 1000)
    })
  })

  context("Task execution approval", () => {
    it("allows setting an approval threshold by the contract manager", async () => {
      await identity.setApprovalThreshold(2, { from: owner })
      const threshold = await identity.approvalThreshold.call()
      assert.equal(Number(threshold), 2)

      // only the owner can do it
      await assertThrows(identity.setApprovalThreshold(3, { from: user1 }))
    })

    it("allows task execution requests to be made (publicly)", async () => {
      const value = 0
      const callData = token.contract.transfer.getData(user5, 700, {
        from: identity.address
      })

      const tasksCount = await identity.tasksCount.call()
      const tx = await identity.execute(token.address, value, callData, {
        from: user4
      })
      // get the task ID
      const log = getLog(tx, "ExecutionRequested")
      executionRequest = Number(log.args.executionId)

      const tasksCount2 = await identity.tasksCount.call()
      assert.equal(Number(tasksCount2), Number(tasksCount) + 1)
    })

    it("only action key holders can approve", async () => {
      await assertThrows(
        identity.approve(executionRequest, true, { from: user4 })
      )
    })

    it("triggers task execution after enough approvals", async () => {
      const bal1 = await token.balanceOf.call(user5)

      // owner has MANAGEMENT_KEY
      await identity.approve(executionRequest, true, { from: owner })
      const bal2 = await token.balanceOf.call(user5)
      assert.equal(Number(bal1), Number(bal2))

      // second approval from ACTION_KEY holder
      const hasActionKey = await identity.addressHasPurpose(user3, ACTION_KEY)
      assert.isTrue(hasActionKey)
      const tx = await identity.approve(executionRequest, true, { from: user3 })
      const log = getLog(tx, "Executed")

      // check the tokens were actually tranferred
      const bal3 = await token.balanceOf.call(user5)
      assert.equal(Number(bal3), 700)
    })

    it("task execution fails properly when needed", async () => {
      // set the threshold back to 1
      await identity.setApprovalThreshold(1, { from: owner })

      //shouldn't be able to make a zero token transfer
      const callData = token.contract.transfer.getData(user5, 999999, {
        from: identity.address
      })
      const tx = await identity.execute(token.address, 0, callData, {
        from: owner
      })
      const log = getLog(tx, "ExecutionFailed")
    })

    it("allows negative approval", async () => {
      // set the threshold back to 2
      //await identity.setApprovalThreshold(2, { from: owner })

      const value = 0
      const callData = token.contract.transfer.getData(user5, 300, {
        from: identity.address
      })
      let tx = await identity.execute(token.address, value, callData, {
        from: user4
      })
      // get the task ID
      let log = getLog(tx, "ExecutionRequested")
      const taskID = Number(log.args.executionId)

      // owner has MANAGEMENT_KEY
      tx = await identity.approve(taskID, false, { from: owner })
      log = getLog(tx, "Approved")
      assert.isFalse(log.args.approved)
    })
  })
})
