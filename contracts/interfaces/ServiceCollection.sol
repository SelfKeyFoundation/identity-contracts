pragma solidity ^0.4.19;


/**
 * @title ServiceCollection
 * @dev Interface for managing DID service endpoints
 */
contract ServiceCollection {

    // Structure for service entries  ???
    struct Service {
        bytes32 _type;
        string serviceEndpoint;
    }

    mapping(bytes32 => string) public servicesByType;
    mapping(bytes32 => uint256) public indexOfServiceType;
    bytes32[] public services;    // array for added services types
    uint256 public servicesCount;

    event ServiceAdded(bytes32 _type);
    event ServiceRemoved(bytes32 _type);
    event ServiceUpdated(bytes32 _type);

    function getServiceByType(bytes32 _type) public view returns (string);
    function addService(bytes32 _type, string _serviceEndpoint) public returns (bool);
    function removeService(bytes32 _type) public returns (bool);
    //function getServices() public view returns (Service[] memory);
}
