const Identity = artifacts.require('./Identity.sol')
const IdentityFactory = artifacts.require('./IdentityFactory.sol')

const assertThrows = require('./utils/assertThrows')
const { getLog } = require('./utils/txHelpers')

const MANAGEMENT_KEY = 1
const ACTION_KEY = 2
const CLAIM_SIGNER_KEY = 3
const ENCRYPTION_KEY = 4

const ETH_ADDR = 1
const RSA = 2
const ECDSA = 3

contract('Identity', accounts => {
  const [owner, user1, user2, user3, user4, user5] = accounts.slice(0)
  let factoryContract

  context('Dynamic deployment of Identity contract', () => {
    let identity

    before(async () => {
      factoryContract = await IdentityFactory.new()
      assert.isNotNull(factoryContract)
    })

    it('deploys successfully through factory contract', async () => {
      const tx = await factoryContract.createIdentity()
      const log = getLog(tx, 'IdentityCreated')
      identity = Identity.at(log.args['idContract'])
      assert.isNotNull(identity)
    })

    it('adds key only if sender has manager role', async () => {
      // Adds a second "manager"
      let tx = await identity.addKey(user2, MANAGEMENT_KEY, ETH_ADDR)

      // New manager is able to add more keys. Adds user3 as an ACTION_KEY
      tx = await identity.addKey(user3, ACTION_KEY, ETH_ADDR, { from: user2 })

      // Fails to add a key if caller has no management key (user3 has only ACTION_KEY)
      await assertThrows(
        identity.addKey(user4, ACTION_KEY, ETH_ADDR, { from: user3 })
      )
    })

    it('retrieves keys successfully', async () => {
      let key = await identity.getKey(user2, MANAGEMENT_KEY)
      assert.equal(key[0], user2)
      key = await identity.getKey(user3, ACTION_KEY)
      assert.equal(key[0], user3)
    })

    it('removes key only if sender has manager role', async () => {
      // Checks key exists first
      let key = await identity.getKey(user2, MANAGEMENT_KEY)
      assert.equal(key[0], user2)

      // Original owner removes key
      let tx = await identity.removeKey(user2, MANAGEMENT_KEY)

      // Checks key was effectively removed
      await assertThrows(identity.getKey(user2, MANAGEMENT_KEY))
    })

    it('adds and retrieves new service endpoints', async () => {
      const serviceEndpoint =
        'https://hub.example.com/.identity/did:key:01234567abcdef/'
      const serviceType = 'HubService'
      await identity.addService(serviceType, serviceEndpoint)
      const gotService = await identity.getServiceByType(serviceType)
      assert.equal(gotService, serviceEndpoint)

      // add a second service endpoint, because why not?
      const serviceEndpoint2 = 'https://example.com/messages/8377464'
      const serviceType2 = 'MessagingService'
      await identity.addService(serviceType2, serviceEndpoint2)
      const gotService2 = await identity.getServiceByType(serviceType2)
      assert.equal(gotService2, serviceEndpoint2)

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 2)
    })

    it('updates existing service endpoint', async () => {
      const serviceEndpoint =
        'https://hub.example.com/.identity/did:key:9876432cdefajj/'
      const serviceType = 'HubService'
      await identity.addService(serviceType, serviceEndpoint)
      const gotService = await identity.getServiceByType(serviceType)
      assert.equal(gotService, serviceEndpoint)

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 2)
    })

    it('removes existing service endpoint', async () => {
      const serviceType = 'HubService'
      await identity.removeService(serviceType)
      await assertThrows(identity.getServiceByType(serviceType))

      // check the services count is correct
      const servicesCount = Number(await identity.servicesCount.call())
      assert.equal(servicesCount, 1)
    })
  })
})
