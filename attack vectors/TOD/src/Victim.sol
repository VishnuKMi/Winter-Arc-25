// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

contract Victim {
    // Assume other required functionality is correctly implemented
    address admin;
    address payable pool;

    constructor(address _admin) {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    function setPoolAddress(address payable _pool) external onlyAdmin {
        pool = _pool;
    }

    function addLiquidity() external payable {
        pool.transfer(msg.value);
    }
}
