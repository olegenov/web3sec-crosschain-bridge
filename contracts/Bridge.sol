// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {BridgedERC20} from "./BridgedERC20.sol";

/// @title Simple role-gated bridge for burn-and-mint transfers
/// @notice Мост с событиями, одноразовыми сообщениями и ролевым доступом для релэйера
contract Bridge is AccessControl, Pausable, ReentrancyGuard {
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    mapping(bytes32 => bool) public processed;

    uint256 public outboundNonce;

    /// @notice Инициирован перевод: токены сожжены на исходной сети
    event TransferInitiated(
        bytes32 indexed messageId,
        uint256 indexed sourceChainId,
        uint256 indexed destChainId,
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 nonce
    );

    /// @notice Завершён перевод: токены отчеканены на целевой сети
    event TransferCompleted(
        bytes32 indexed messageId,
        uint256 indexed sourceChainId,
        uint256 indexed destChainId,
        address token,
        address sender,
        address recipient,
        uint256 amount
    );

    error AlreadyProcessed(bytes32 messageId);
    error InvalidDestination(uint256 expected, uint256 actual);
    error ZeroAmount();

    constructor(address admin) {
        require(admin != address(0), "admin is zero");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Пользователь инициирует кроссчейн перевод: сжигаем его токены и эмитим событие
    function sendToChain(
        uint256 destChainId,
        address token,
        address recipient,
        uint256 amount
    ) external nonReentrant whenNotPaused {
        if (amount == 0) revert ZeroAmount();

        BridgedERC20(token).burn(msg.sender, amount);

        uint256 nonce = ++outboundNonce;
        bytes32 messageId = computeMessageId(
            block.chainid,
            destChainId,
            token,
            msg.sender,
            recipient,
            amount,
            nonce
        );

        emit TransferInitiated(
            messageId,
            block.chainid,
            destChainId,
            token,
            msg.sender,
            recipient,
            amount,
            nonce
        );
    }

    /// @notice Релэйер завершает перевод на целевой сети, чеканя токены получателю
    function receiveFromChain(
        uint256 sourceChainId,
        uint256 destChainId,
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) external nonReentrant onlyRole(RELAYER_ROLE) whenNotPaused {
        if (destChainId != block.chainid) revert InvalidDestination(block.chainid, destChainId);
        if (amount == 0) revert ZeroAmount();

        bytes32 messageId = computeMessageId(
            sourceChainId,
            destChainId,
            token,
            sender,
            recipient,
            amount,
            nonce
        );
        if (processed[messageId]) revert AlreadyProcessed(messageId);
        processed[messageId] = true;

        BridgedERC20(token).mint(recipient, amount);

        emit TransferCompleted(
            messageId,
            sourceChainId,
            destChainId,
            token,
            sender,
            recipient,
            amount
        );
    }

    /// @notice Детерминированный id сообщения: используется для защиты от повторов
    function computeMessageId(
        uint256 sourceChainId,
        uint256 destChainId,
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(sourceChainId, destChainId, token, sender, recipient, amount, nonce));
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
