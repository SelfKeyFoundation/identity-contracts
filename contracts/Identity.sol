pragma solidity ^0.4.19;

import './interfaces/ERC725b.sol';
import './interfaces/ServiceCollection.sol';


import 'zeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

/**
 * @title Identity
 * @dev Contract that represents an identity
 */
contract Identity is ERC725b, ServiceCollection, Ownable, Destructible {
    using SafeERC20 for ERC20;

    bytes16 version = "0.1.1";

    event ReceivedETH(uint256 amount, address sender);
    event ReceivedERC20(uint256 amount, address sender, address token);

    modifier onlyManager () {
        require(keys[keccak256(msg.sender, MANAGEMENT_KEY)].key != 0);
        _;
    }

    /**
     * @dev Identity Constructor. Assigns a Management key to the creator.
     * @param id_owner — The creator of this identity.
     */
    function Identity(address id_owner) public {
        owner = id_owner;
        // Adds sender as a management key
        keys[keccak256(id_owner, MANAGEMENT_KEY)] = Key(id_owner, MANAGEMENT_KEY, ECDSA);
    }

    /**
     * @dev Fallback function. Allows the contract to receive ETH payments
     */
    function()
        public
        payable
    {
        ReceivedETH(msg.value, msg.sender);
    }

    /**
     * @dev Adds a new key (address) to the identity
     * @param _key — The key (address) to be added
     * @param _type — The key type (Management, Action, etc)
     * @param _scheme — The scheme to be used for verifying this key (ECDSA, RSA, etc)
     */
    function addKey(address _key, uint256 _type, uint256 _scheme)
        onlyManager
        public
        returns (bool)
    {
        bytes32 kec = keccak256(_key, _type);
        keys[kec] = Key(_key, _type, _scheme);
        keyHashes.push(kec);
        indexOfKeyHash[kec] = keysCount;
        keysCount = keysCount + 1;

        KeyAdded(_key, _type);

        return true;
    }

    /**
     * @dev Retrieves a key by its address and type
     * @param _key — The key (address) to be retrieved
     * @param _type — The key type (Management, Action, etc)
     */
    function getKey(address _key, uint256 _type)
        public
        view
        returns (address, uint256, uint256)
    {
        bytes32 index = keccak256(_key, _type);
        require(keys[index].key != 0);

        return (keys[index].key, keys[index].keyType, keys[index].scheme);
    }

    /**
     * @dev Removes a key (doable only by addresses added of the MANAGEMENT type)
     * @param _key — The key (address) to be removed
     * @param _type — The key type (Management, Action, etc)
     */
    function removeKey(address _key, uint256 _type)
        onlyManager
        public
        returns (bool)
    {
        bytes32 _hash = keccak256(_key, _type);
        uint256 index = indexOfKeyHash[_hash];
        delete keys[_hash];
        keyHashes[index] = keyHashes[keysCount - 1];    // moves last element to deleted slot
        keysCount = keysCount - 1;
        KeyRemoved(_key, _type);

        return true;
    }

    /**
     * @dev Adds a service endpoint to the identity
     * @param _type — The service type (short string)
     * @param _endpoint — The service endpoint URI
     */
    function addService(bytes32 _type, string _endpoint)
        public
        onlyManager
        returns (bool)
    {
        bytes memory serviceBytes = bytes(servicesByType[_type]);
        if (serviceBytes.length == 0) {
            // service of such type doesn't exist yet
            services.push(_type);
            indexOfServiceType[_type] = servicesCount;
            servicesCount = servicesCount + 1;
        }
        servicesByType[_type] = _endpoint;
        ServiceAdded(_type);

        return true;
    }

    /**
     * @dev Gets a service endpoint given a type
     * @param _type — The service type (short string) E.g. "HubService"
     */
    function getServiceByType(bytes32 _type)
        public
        view
        returns (string)
    {
        bytes memory serviceBytes = bytes(servicesByType[_type]);
        require(serviceBytes.length > 0);

        return servicesByType[_type];
    }

    /**
     * @dev Removes a service endpoint of the given type
     * @param _type — The service type (short string) E.g. "HubService"
     */
    function removeService(bytes32 _type)
        public
        onlyManager
        returns (bool)
    {
        bytes memory serviceBytes = bytes(servicesByType[_type]);
        require(serviceBytes.length > 0);


        uint256 index = indexOfServiceType[_type];
        delete servicesByType[_type];
        services[index] = services[servicesCount - 1];    // moves last element to deleted slot
        servicesCount = servicesCount - 1;
        ServiceRemoved(_type);

        return true;
    }

    /**
     * @dev Withdraws ETH held by the identity contract
     * @param amount — The amount of ETH to be withdrawn
     */
    function withdrawEth(uint256 amount)
        public
        onlyManager
    {
        require(amount <= this.balance);
        msg.sender.transfer(amount);
    }

    /**
     * @dev Withdraws ERC20 tokens held by the identity contract
     * @param amount — The amount of tokens to be withdrawn
     */
    function withdrawERC20(uint256 amount, address tokenAddress)
        public
        onlyManager
    {
        ERC20 token = ERC20(tokenAddress);      // does this work?
        // validate this is an ERC20 address
        require(amount <= token.balanceOf(this));
        token.safeTransfer(msg.sender, amount);
    }
}
