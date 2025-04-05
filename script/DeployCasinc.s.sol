// SPDX-License-Identifier:MIT
pragma solidity ^0.8.15;

import {Script} from "../lib/forge-std/src/Script.sol";
import {Casinc} from "../src/Casinc.sol";

contract DeployCasinc is Script {
    function run() external {
        vm.startBroadcast();
        new Casinc();

        vm.stopBroadcast();
    }
}
