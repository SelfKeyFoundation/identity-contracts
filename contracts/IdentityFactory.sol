pragma solidity ^0.4.19;

import './Identity.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';
import 'openzeppelin-solidity/contracts/lifecycle/Destructible.sol';

/**
 * @title IdentityFactory
 * @dev Middleware contract for the deployment of new Identity instances
 */
contract IdentityFactory is Ownable, Destructible {

    event IdentityCreated(address sender, address idContract);

    constructor()
        public
    {
    }

    function createIdentity()
        public      // should be public? Or should only IdentityRegistry/Manager be able to invoke?
    {
        Identity newId = new Identity(msg.sender);   //save reference somewhere?
        emit IdentityCreated(msg.sender, address(newId));
    }
}
