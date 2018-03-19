pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/ownership/Ownable.sol';
import 'zeppelin-solidity/contracts/lifecycle/Destructible.sol';

/**
 * @title Identity
 * @dev Contract that represents an identity
 */
contract Identity is Ownable, Destructible {
    bytes16 idVersion = "0.0.1";

    // TODO: Add constants for key schemes

    // TODO: move to an interface
    uint256 constant MANAGEMENT_KEY = 1;
    uint256 constant ACTION_KEY = 2;
    uint256 constant CLAIM_SIGNER_KEY = 3;
    uint256 constant ENCRYPTION_KEY = 4;

    struct Key {
        address key;    //ERC725 defines it as bytes32
        uint256 keyType;
        uint256 scheme;
    }

    // maps from type to keys
    mapping(bytes32 => Key) keys;

    event KeyAdded(address indexed key, uint256 indexed keyType);
    event KeyRemoved(address indexed key, uint256 indexed keyType);

    modifier onlyManager () {
        require(keys[keccak256(msg.sender, MANAGEMENT_KEY)].key != 0);
        _;
    }

    function Identity(address sender) public {
        // Adds sender as a management key
        keys[keccak256(sender, MANAGEMENT_KEY)] = Key(sender, MANAGEMENT_KEY, 1);   // TODO: set proper scheme argument
    }

    function addKey(address _key, uint256 _type, uint256 _scheme)
        onlyManager
        public
        returns (bool)
    {
        keys[keccak256(_key, _type)] = Key(_key, _type, _scheme);
        KeyAdded(_key, _type);

        return true;
    }

    function getKey(address _key, uint256 _type)
        public
        view
        returns (address, uint256, uint256)
    {
        bytes32 index = keccak256(_key, _type);
        require(keys[index].key != 0);

        return (keys[index].key, keys[index].keyType, keys[index].scheme);
    }

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
