// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {BridgedERC20} from "../contracts/BridgedERC20.sol";

contract BridgedERC20Test is Test {
    BridgedERC20 private token;

    address private admin = address(0xA);
    address private minter = address(0xB);
    address private burner = address(0xC);
    address private user = address(0xD);

    function setUp() public {
        token = new BridgedERC20("Bridged Token", "BRG", admin);

        vm.startPrank(admin);
        token.grantRole(token.MINTER_ROLE(), minter);
        token.grantRole(token.BURNER_ROLE(), burner);
        vm.stopPrank();
    }

    function test_AdminHasDefaultAdminRole() public view {
        assertTrue(token.hasRole(token.DEFAULT_ADMIN_ROLE(), admin));
    }

    function test_MintByMinter() public {
        vm.prank(minter);
        token.mint(user, 100);

        assertEq(token.balanceOf(user), 100);
        assertEq(token.totalSupply(), 100);
    }

    function test_RevertMintWithoutRole() public {
        vm.expectRevert();
        token.mint(user, 1);
    }

    function test_BurnByBurner() public {
        vm.prank(minter);
        token.mint(user, 100);

        vm.prank(burner);
        token.burn(user, 40);

        assertEq(token.balanceOf(user), 60);
        assertEq(token.totalSupply(), 60);
    }

    function test_RevertBurnWithoutRole() public {
        vm.prank(minter);
        token.mint(user, 10);

        vm.expectRevert();
        token.burn(user, 5);
    }
}
