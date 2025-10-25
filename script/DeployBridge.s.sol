// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Bridge} from "../contracts/Bridge.sol";

contract DeployBridge is Script {
    function run() external {
        address admin = vm.envAddress("ADMIN_ADDRESS");
        require(admin != address(0), "ADMIN_ADDRESS is required");

        vm.startBroadcast();
        Bridge bridge = new Bridge(admin);
        vm.stopBroadcast();

        console2.log("Bridge deployed at", address(bridge));
    }
}
