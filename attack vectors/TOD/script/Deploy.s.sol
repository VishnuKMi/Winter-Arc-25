// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { console2 } from "forge-std/src/Script.sol";
import { Victim } from "../src/Victim.sol";
import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/guides/scripting-with-solidity
contract Deploy is BaseScript {
    function run() public broadcast returns (Victim victim) {
        address admin = msg.sender;
        victim = new Victim(admin);

        console2.log("Victim contract deployed at:", address(victim));
        console2.log("Admin:", admin);
    }
}
