// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {Bridge} from "../contracts/Bridge.sol";
import {BridgedERC20} from "../contracts/BridgedERC20.sol";

contract BridgeTest is Test {
    Bridge private bridgeSrc;
    Bridge private bridgeDst;
    BridgedERC20 private tokenA;
    BridgedERC20 private tokenB;

    address private admin = address(this);
    address private relayer = address(0xB);
    address private user = address(0xC);

    function setUp() public {
        bridgeSrc = new Bridge(admin);
        bridgeDst = new Bridge(admin);

        tokenA = new BridgedERC20("Bridged Token", "BRG", admin);
        tokenB = new BridgedERC20("Bridged Token", "BRG", admin);

        vm.startPrank(admin);
        tokenA.grantRole(tokenA.BURNER_ROLE(), address(bridgeSrc));
        tokenB.grantRole(tokenB.MINTER_ROLE(), address(bridgeDst));
        bridgeSrc.grantRole(bridgeSrc.RELAYER_ROLE(), relayer);
        bridgeDst.grantRole(bridgeDst.RELAYER_ROLE(), relayer);
        vm.stopPrank();

        vm.startPrank(admin);
        tokenA.grantRole(tokenA.MINTER_ROLE(), address(this));
        tokenA.mint(user, 1000);
        vm.stopPrank();
    }

    function test_EmitTransferInitiated() public {
        uint256 nextNonce = bridgeSrc.outboundNonce() + 1;
        uint256 sourceChainId = block.chainid;
        uint256 destChainId = 200;
        uint256 amount = 123;

        bytes32 expectedMessageId = bridgeSrc.computeMessageId(
            sourceChainId,
            destChainId,
            address(tokenA),
            user,
            user,
            amount,
            nextNonce
        );

        vm.expectEmit(true, true, true, true, address(bridgeSrc));
        emit Bridge.TransferInitiated(
            expectedMessageId,
            sourceChainId,
            destChainId,
            address(tokenA),
            user,
            user,
            amount,
            nextNonce
        );

        vm.prank(user);
        bridgeSrc.sendToChain(destChainId, address(tokenA), user, amount);
    }

    function test_BurnOnSourceAndMintOnDest() public {
        vm.startPrank(user);
        bridgeSrc.sendToChain(200, address(tokenA), user, 250);
        vm.stopPrank();

        uint256 sourceChainId = block.chainid;
        vm.chainId(200);
        vm.startPrank(relayer);
        bridgeDst.receiveFromChain(sourceChainId, 200, address(tokenB), user, user, 250, bridgeSrc.outboundNonce());
        vm.stopPrank();
        vm.chainId(sourceChainId);

        assertEq(tokenA.balanceOf(user), 750);
        assertEq(tokenB.balanceOf(user), 250);
    }

    function test_EmitTransferCompleted() public {
        vm.prank(user);
        bridgeSrc.sendToChain(200, address(tokenA), user, 42);

        uint256 nonce = bridgeSrc.outboundNonce();
        uint256 sourceChainId = block.chainid;
        uint256 destChainId = 200;

        bytes32 expectedMsgId = bridgeDst.computeMessageId(
            sourceChainId,
            destChainId,
            address(tokenB),
            user,
            user,
            42,
            nonce
        );

        vm.chainId(destChainId);
        vm.expectEmit(true, true, true, true, address(bridgeDst));
        emit Bridge.TransferCompleted(
            expectedMsgId,
            sourceChainId,
            destChainId,
            address(tokenB),
            user,
            user,
            42
        );

        vm.prank(relayer);
        bridgeDst.receiveFromChain(sourceChainId, destChainId, address(tokenB), user, user, 42, nonce);
        vm.chainId(sourceChainId);
    }

    function test_ReplayProtection() public {
        vm.prank(user);
        bridgeSrc.sendToChain(200, address(tokenA), user, 100);

        uint256 nonce = bridgeSrc.outboundNonce();
        uint256 sourceChainId = block.chainid;

        vm.chainId(200);
        vm.startPrank(relayer);
        bridgeDst.receiveFromChain(sourceChainId, 200, address(tokenB), user, user, 100, nonce);

        bytes32 msgId = bridgeDst.computeMessageId(sourceChainId, 200, address(tokenB), user, user, 100, nonce);
        vm.expectRevert(abi.encodeWithSelector(Bridge.AlreadyProcessed.selector, msgId));
        bridgeDst.receiveFromChain(sourceChainId, 200, address(tokenB), user, user, 100, nonce);
        vm.stopPrank();
        vm.chainId(sourceChainId);
    }
}
