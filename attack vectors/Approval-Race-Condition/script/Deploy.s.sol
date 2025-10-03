// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { VictimWallet } from "../src/VictimWallet.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/guides/scripting-with-solidity
contract Deploy is BaseScript {
    function run() public broadcast returns (VictimWallet victim) {
        victim = new VictimWallet();
    }
}
