// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import {BridgedERC20} from "../contracts/BridgedERC20.sol";

contract MintToken is Script {
    function run() external {
        address tokenAddr = vm.envAddress("TOKEN_ADDRESS");
        address to = vm.envAddress("MINT_TO");
        uint256 amount = vm.envUint("MINT_AMOUNT");
        require(tokenAddr != address(0) && to != address(0), "env missing");
        require(amount > 0, "amount=0");

        vm.startBroadcast();
        BridgedERC20(tokenAddr).mint(to, amount);
        vm.stopBroadcast();

        console2.log("Minted", amount, "to", to);
    }
}
