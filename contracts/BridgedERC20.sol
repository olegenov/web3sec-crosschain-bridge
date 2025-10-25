// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Bridged ERC20 Token with role-based mint/burn
/// @notice Токен для кроссчейн-моста: чеканка и сжигание доступны только доверенным адресам
contract BridgedERC20 is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @param name_ Имя токена
    /// @param symbol_ Символ токена
    /// @param admin Адрес администратора
    constructor(string memory name_, string memory symbol_, address admin) ERC20(name_, symbol_) {
        require(admin != address(0), "admin is zero");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    /// @notice Чеканка токенов. Доступно только адресам с MINTER_ROLE
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /// @notice Сжигание токенов со счета `from`. Доступно только адресам с BURNER_ROLE
    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }
}
