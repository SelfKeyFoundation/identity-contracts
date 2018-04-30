pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';


/**
 *  A dummy ERC20 token used for testing.
 */
contract ERC20Mock is StandardToken {
    string public constant name = 'MockToken5000'; //solhint-disable-line const-name-snakecase
    string public constant symbol = 'M5K'; //solhint-disable-line const-name-snakecase
    uint256 public constant decimals = 0; //solhint-disable-line const-name-snakecase

    uint256 MAX_SUPPLY = 5000;

    constructor() public {
        balances[msg.sender] = MAX_SUPPLY;
    }
}
