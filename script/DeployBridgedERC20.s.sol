// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {BridgedERC20} from "../contracts/BridgedERC20.sol";

contract DeployBridgedERC20 is Script {
    function run() external {
        string memory name = vm.envOr("TOKEN_NAME", string("Bridged Token"));
        string memory symbol = vm.envOr("TOKEN_SYMBOL", string("BRG"));
        address admin = vm.envAddress("ADMIN_ADDRESS");

        require(admin != address(0), "ADMIN_ADDRESS is required");

        vm.startBroadcast();
        BridgedERC20 token = new BridgedERC20(name, symbol, admin);
        vm.stopBroadcast();

        console2.log("BridgedERC20 deployed at", address(token));
    }
}
