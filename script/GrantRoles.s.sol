// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {BridgedERC20} from "../contracts/BridgedERC20.sol";

contract GrantRoles is Script {
    function run() external {
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address minter = vm.envAddress("MINTER_ADDRESS");
        address burner = vm.envAddress("BURNER_ADDRESS");

        require(tokenAddr != address(0), "TOKEN_ADDRESS is required");
        require(minter != address(0), "MINTER_ADDRESS is required");
        require(burner != address(0), "BURNER_ADDRESS is required");

        vm.startBroadcast();
        BridgedERC20 token = BridgedERC20(tokenAddr);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURNER_ROLE(), burner);
        vm.stopBroadcast();

        console2.log("Granted roles to:");
        console2.log("  MINTER:", minter);
        console2.log("  BURNER:", burner);
    }
}
