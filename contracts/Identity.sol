pragma solidity ^0.4.19;

import './interfaces/ERC725b.sol';
import './interfaces/ServiceCollection.sol';


import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

/**
 * @title Identity
 * @dev Contract that represents an identity
 */
contract Identity is ERC725b, ServiceCollection, Ownable, Destructible {
    bytes16 idVersion = "0.0.1";

    modifier onlyManager () {
        require(keys[keccak256(msg.sender, MANAGEMENT_KEY)].key != 0);
        _;
    }

    /**
     * @dev Identity Constructor. Assigns a Management key to the creator.
     * @param id_owner — The creator of this identity.
     */
    function Identity(address id_owner) public {
        // Adds sender as a management key
        keys[keccak256(id_owner, MANAGEMENT_KEY)] = Key(id_owner, MANAGEMENT_KEY, ECDSA);
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
        keys[keccak256(_key, _type)] = Key(_key, _type, _scheme);
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
        bytes32 index = keccak256(_key, _type);
        delete keys[index];
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

        servicesByType[_type] = "";
        uint256 index = indexOfServiceType[_type];
        // What to do with the indexOfServiceType of the deleted service????
        services[index] = services[servicesCount - 1];    // moves last element to deleted slot
        servicesCount = servicesCount - 1;

        return true;
    }
}
