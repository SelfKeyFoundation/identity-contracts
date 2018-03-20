pragma solidity ^0.4.19;

import './lib/ERC725b.sol';

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

/**
 * @title Identity
 * @dev Contract that represents an identity
 */
contract Identity is ERC725b, Ownable, Destructible {
    bytes16 idVersion = "0.0.1";

    modifier onlyManager () {
        require(keys[keccak256(msg.sender, MANAGEMENT_KEY)].key != 0);
        _;
    }

    /**
     * @dev Identity Constructor. Assigns a Management key to the creator.
     * @param _sender — The creator of this identity.
     */
    function Identity(address sender) public {
        // Adds sender as a management key
        keys[keccak256(sender, MANAGEMENT_KEY)] = Key(sender, MANAGEMENT_KEY, ECDSA);
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
}
