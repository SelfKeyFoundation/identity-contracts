pragma solidity ^0.4.23;


/**
 * @title ERC725
 * @dev Identity interface _based_ on the ERC725 proposal
 */
contract ERC725 {
    // Constants for key types (purposes)
    uint256 public constant MANAGEMENT_KEY = 1;
    uint256 public constant ACTION_KEY = 2;
    uint256 public constant CLAIM_SIGNER_KEY = 3;
    uint256 public constant ENCRYPTION_KEY = 4;

    // Key constant types
    uint256 public constant ETH_ADDR = 1;
    uint256 public constant RSA = 2;
    uint256 public constant ECDSA = 3;

    bytes32[] public keyIndexes;

    mapping(bytes32 => Key) public keys;
    mapping(bytes32 => uint256) public indexOfKey;

    // counters
    uint256 public keysCount = 0;
    uint256 public tasksCount = 0;

    mapping (uint256 => Task) public tasks;
    uint256 public approvalThreshold = 1;

    struct Key {
        bytes32 key;
        uint256 purpose;
        uint256 keyType;
    }

    struct Task {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
        uint256 approvals;
    }

    event KeyAdded(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event KeyRemoved(bytes32 indexed key, uint256 indexed purpose, uint256 indexed keyType);
    event Executed(uint256 indexed taskId, address indexed to, uint256 indexed value, bytes data);
    event Approved(uint256 indexed taskId, bool approved);

    event ExecutionRequested(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data);

    event ExecutionFailed(
        uint256 indexed executionId,
        address indexed to,
        uint256 indexed value,
        bytes data);

    function getKey(bytes32 _key) public view returns (bytes32, uint256, uint256);
    function keyHasPurpose(bytes32 _key, uint256 purpose) public view returns(bool);
    //function getKeysByPurpose(uint256 _purpose) constant returns(bytes32[] keys);
    function addKey(bytes32 _key, uint256 _purpose, uint256 _keyType) public returns (bool);
    function removeKey(bytes32 _key) public returns (bool);
    //function replaceKey(address _oldKey, address _newKey) public returns (bool success);
    function execute(address _to, uint256 _value, bytes _data) public returns (uint256);
    function approve(uint256 _id, bool _approve) public returns (bool);
}
