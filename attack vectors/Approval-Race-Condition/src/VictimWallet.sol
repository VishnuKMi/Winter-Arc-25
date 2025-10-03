// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title VictimWallet - Simple wallet with approval race condition
 * @notice A basic wallet that lets users approve others to spend their funds
 * @dev VULNERABLE: The approve() function has an approval race condition
 */
contract VictimWallet {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;

    event Deposited(address indexed user, uint256 amount);
    event Approved(address indexed owner, address indexed spender, uint256 amount);
    event Spent(address indexed spender, address indexed owner, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Deposit ETH into your wallet
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit something");
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    /**
     * @notice Approve someone to spend your funds
     * @dev VULNERABLE: Overwrites allowance without checking previous value
     * This is the bug that enables the attack!
     */
    function approve(address spender, uint256 amount) external {
        allowances[msg.sender][spender] = amount;
        emit Approved(msg.sender, spender, amount);
    }

    /**
     * @notice Spend funds on behalf of someone who approved you
     */
    function spendFrom(address owner, uint256 amount) external {
        require(allowances[owner][msg.sender] >= amount, "Insufficient allowance");
        require(balances[owner] >= amount, "Insufficient balance");

        allowances[owner][msg.sender] -= amount;
        balances[owner] -= amount;
        balances[msg.sender] += amount;

        emit Spent(msg.sender, owner, amount);
    }

    /**
     * @notice Withdraw your funds
     */
    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;

        // wake-disable-next-line
        (bool success,) = msg.sender.call{ value: amount }("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }
}
