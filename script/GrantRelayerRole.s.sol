// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Bridge} from "../contracts/Bridge.sol";

contract GrantRelayerRole is Script {
    function run() external {
        address bridgeAddr = vm.envAddress("BRIDGE_ADDRESS");
        address relayer = vm.envAddress("RELAYER_ADDRESS");
        require(bridgeAddr != address(0), "BRIDGE_ADDRESS is required");
        require(relayer != address(0), "RELAYER_ADDRESS is required");

        vm.startBroadcast();
        Bridge(bridgeAddr).grantRole(Bridge(bridgeAddr).RELAYER_ROLE(), relayer);
        vm.stopBroadcast();

        console2.log("Granted RELAYER_ROLE to:", relayer);
    }
}
