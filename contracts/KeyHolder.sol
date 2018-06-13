pragma solidity ^0.4.23;

import './interfaces/ERC725.sol';

contract KeyHolder is ERC725 {

    modifier onlyManager () {
        require(keyHasPurpose(keccak256(msg.sender), MANAGEMENT_KEY));
        _;
    }

    /*modifier onlyManagerOrSelf () {
        require(msg.sender == address(this) ||
            keyHasPurpose(keccak256(msg.sender), MANAGEMENT_KEY));
        _;
    }*/

    /**
     * @dev Adds a new key (32 byte hash) to the identity
     * @param _key — The key to be added
     * @param _purpose — The key purpose (Management, Action, etc)
     * @param _keyType — The cryptographic type (scheme) of the key (ECDSA, RSA, etc)
     */
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType)
        onlyManager
        public
        returns (bool)
    {
        _addKey(_key, _purpose, _keyType);

        return true;
    }

    /**
     * @dev Adds a new address converted to a 32 bytes hash
     * @param _address — The address to be added
     * @param _purpose — The key purpose (Management, Action, etc)
     * @param _keyType — The cryptographic type (scheme) of the key (ECDSA, RSA, etc)
     */
    function addAddressAsKey(address _address, uint256 _purpose, uint256 _keyType)
        onlyManager
        public
        returns (bool)
    {
        _addKey(keccak256(_address), _purpose, _keyType);

        return true;
    }

    /**
     * @dev Internal function where key addition logic is implemented
     */
    function _addKey(bytes32 _key, uint256 _purpose, uint256 _keyType)
        internal
    {
        // key must not exist already
        require(keys[_key].key != _key);

        keyIndexes.push(_key);
        indexOfKey[_key] = keysCount;
        keysCount = keysCount + 1;

        keys[_key] = Key(_key, _purpose, _keyType);
        emit KeyAdded(_key, _purpose, _keyType);
    }

    /**
     * @dev Retrieves a key if it exists. Reverts otherwise.
     * @param _key — The key (32 byte hash) to be retrieved
     */
    function getKey(bytes32 _key)
        public
        view
        returns (bytes32, uint256, uint256)
    {
        require(keys[_key].key == _key, "Key does not exist");
        return (keys[_key].key, keys[_key].purpose, keys[_key].keyType);
    }

    /**
     * @dev Retrieves the key that corresponds to an Ethereum address, if it exists
     * @param _address — The address from which the key will be retrieved
     */
    function getKeyByAddress(address _address)
        public
        view
        returns (bytes32, uint256, uint256)
    {
        return getKey(keccak256(_address));
    }

    /**
     * @dev Removes a key (doable only by holders of MANAGEMENT keys)
     * @param _key — The key to be removed
     */
    function removeKey(bytes32 _key)
        onlyManager
        public
        returns (bool)
    {
        require(keys[_key].key == _key, "Key does not exist");

        uint256 index = indexOfKey[_key];
        keyIndexes[index] = keyIndexes[keysCount - 1];    // moves last element to deleted slot
        keysCount = keysCount - 1;
        delete keys[_key];
        emit KeyRemoved(_key, keys[_key].purpose, keys[_key].keyType);

        return true;
    }


    /**
     * @dev Returns true if a key is present and has the given purpose.
     * If key is not present it returns false.
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose)
        public
        view
        returns(bool result)
    {
        if (keys[_key].key == 0) return false;
        return keys[_key].purpose <= _purpose;
    }

    /**
     * @dev Wrapper for keyHasPurpose method. Returns true if keccak hash of an address is a valid
     * key and has the given purpose.
     */
    function addressHasPurpose(address _address, uint256 _purpose)
        public
        view
        returns(bool result)
    {
        return keyHasPurpose(keccak256(_address), _purpose);
    }

}
