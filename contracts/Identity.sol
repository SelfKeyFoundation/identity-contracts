pragma solidity ^0.4.23;

import './KeyHolder.sol';
import './interfaces/ServiceCollection.sol';

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Destructible.sol';

import 'selfkey-staking/contracts/StakingManager.sol';
import 'selfkey-name-registry/contracts/NameRegistry.sol';

/**
 * @title Identity
 * @dev Contract that represents an identity
 */
contract Identity is KeyHolder, ServiceCollection, Ownable, Destructible {
    using SafeERC20 for ERC20;

    bytes16 version = "0.1.1";

    event ReceivedETH(uint256 amount, address sender);
    event ReceivedERC20(uint256 amount, address sender, address token);

    /**
     * @dev Identity Constructor. Assigns a Management key to the creator.
     * @param id_owner — The creator of this identity.
     */
    constructor(address id_owner) public {
        owner = id_owner;
        _addKey(keccak256(id_owner), MANAGEMENT_KEY, ECDSA);   // Adds sender as a management key
    }

    /**
     * @dev Fallback function. Allows the contract to receive ETH payments
     */
    function()
        public
        payable
    {
        if (msg.value > 0) {
            emit ReceivedETH(msg.value, msg.sender);
        }
    }

    /**
     * @dev Withdraws ETH held by the identity contract
     * @param amount — The amount of ETH to be withdrawn
     */
    function withdrawEth(uint256 amount)
        public
        onlyManager
    {
        require(amount <= address(this).balance);
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
        ERC20 token = ERC20(tokenAddress);
        require(amount <= token.balanceOf(address(this)));
        token.safeTransfer(msg.sender, amount);
    }

    /**
     * @dev ID manager can set how many approvals need to be done to execute a task
     */
    function setApprovalThreshold(uint256 threshold)
        public
        onlyManager
    {
        approvalThreshold = threshold;
    }

    /**
     * @dev Executes an action on other contracts, or itself, or a transfer of ether.
     * 1 or more approvals could be required.
     */
    function execute(address _to, uint256 _value, bytes _data)
        public
        returns (uint256 executionId)
    {
        tasks[tasksCount].to = _to;
        tasks[tasksCount].value = _value;
        tasks[tasksCount].data = _data;

        emit ExecutionRequested(tasksCount, _to, _value, _data);

        if (keyHasPurpose(keccak256(msg.sender), ACTION_KEY))
        {
            approve(tasksCount, true);
        }

        tasksCount = tasksCount + 1;
        return tasksCount - 1;
    }

    /**
     * @dev Approves an execution or claim addition.
     */
    function approve(uint256 _id, bool _approve)
        public
        onlyActionKeyHolder
        returns (bool success)
    {
        if (_approve == true) {
            tasks[_id].approvals += 1;
            if (tasks[_id].approvals >= approvalThreshold) {
                tasks[_id].approved = true;
                success = tasks[_id].to.call(tasks[_id].data, tasks[_id].value);
                if (success) {
                    tasks[_id].executed = true;
                    emit Executed(
                        _id,
                        tasks[_id].to,
                        tasks[_id].value,
                        tasks[_id].data
                    );
                    return true;
                } else {
                    emit ExecutionFailed(
                        _id,
                        tasks[_id].to,
                        tasks[_id].value,
                        tasks[_id].data
                    );
                    return false;
                }
            }
        } else {
            tasks[_id].approved = false;  //???
        }

        emit Approved(_id, _approve);
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
        emit ServiceAdded(_type);

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
        emit ServiceRemoved(_type);

        return true;
    }

    /*function stake(address stakingAddress, uint256 amount, bytes32 serviceID)
        public
        onlyActionKeyHolder
    {
        StakingManager staking = StakingManager(stakingAddress);
        ERC20 token = ERC20(address(staking.token));
        token.approve(stakingAddress, amount);
        staking.stake(amount, serviceID);

    }

    function registerName(address registryAddress, bytes32 name)
        public onlyActionKeyHolder
    {
        NameRegistry registry = NameRegistry(registryAddress);
        registry.registerName(name);
        // change registerName function to return proper bool?
    }*/
}
