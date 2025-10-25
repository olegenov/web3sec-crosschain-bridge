// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {Bridge} from "../contracts/Bridge.sol";

contract SendToChain is Script {
    function run() external {
        address bridgeAddr = vm.envAddress("BRIDGE_ADDRESS");
        address token = vm.envAddress("SOURCE_TOKEN_ADDRESS");
        address recipient = vm.envAddress("RECIPIENT_ADDRESS");
        uint256 destChainId = vm.envUint("DEST_CHAIN_ID");
        uint256 amount = vm.envUint("AMOUNT");

        require(bridgeAddr != address(0) && token != address(0) && recipient != address(0), "env missing");
        require(amount > 0, "amount=0");

        vm.startBroadcast();
        Bridge(bridgeAddr).sendToChain(destChainId, token, recipient, amount);
        vm.stopBroadcast();

        console2.log("sendToChain submitted");
    }
}
