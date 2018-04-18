pragma solidity ^0.4.19;


/**
 * @title ERC725b
 * @dev Identity interface _based_ on the ERC725 proposal
 */
contract ERC725b {
    // Constants for key types (purposes)
    uint256 public constant MANAGEMENT_KEY = 1;
    uint256 public constant ACTION_KEY = 2;
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    uint256 public constant ENCRYPTION_KEY = 4;

    // Constants for key schemes
    uint256 public constant ETH_ADDR = 1;
    uint256 public constant RSA = 2;
    uint256 public constant ECDSA = 3;

    struct Key {
        address key;    //ERC725 defines it as bytes32
        uint256 keyType;
        uint256 scheme;
    }

    mapping(bytes32 => Key) public keys;    // Keys by type
    bytes32[] public keyHashes;
    mapping(bytes32 => uint256) public indexOfKeyHash;

    uint256 public keysCount = 0;

    event KeyAdded(address indexed key, uint256 indexed keyType);
    event KeyRemoved(address indexed key, uint256 indexed keyType);
    //event KeyReplaced(address indexed oldKey, address indexed newKey, uint256 indexed keyType);
    //event ExecutionRequested(bytes32 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    //event Executed(bytes32 indexed executionId, address indexed to, uint256 indexed value, bytes data);
    //event Approved(bytes32 indexed executionId, bool approved);

    function getKey(address _key, uint256 _type) public view returns (address, uint256, uint256);
    function addKey(address _key, uint256 _type, uint256 _scheme) public returns (bool);
    function removeKey(address _key, uint256 _type) public returns (bool);
    //function replaceKey(address _oldKey, address _newKey) public returns (bool success);
    //function execute(address _to, uint256 _value, bytes _data) public returns (bytes32 executionId);
    //function approve(bytes32 _id, bool _approve) public returns (bool success);
}
