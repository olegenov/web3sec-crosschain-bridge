# web3sec-crosschain-bridge

## Отчёт

### Краткое описание архитектуры моста
- **Модель**: burn-and-mint для сохранения общего предложения.
- **Контракты**:
  - `BridgedERC20` — ERC‑20 с ролями `MINTER_ROLE`/`BURNER_ROLE` (mint/burn доступны только доверенным адресам).
  - `Bridge` — инициирует перевод (сжигает в исходной сети), завершает перевод (чеканит в целевой сети), хранит анти‑реплей `processed[messageId]`, имеет роль `RELAYER_ROLE` для завершающих вызовов.
- **События**:
  - `TransferInitiated(messageId, sourceChainId, destChainId, token, sender, recipient, amount, nonce)` — фиксация депозита/сжигания.
  - `TransferCompleted(messageId, sourceChainId, destChainId, token, sender, recipient, amount)` — фиксация выпуска на целевой сети.
- **Анти‑реплей**: `messageId = keccak256(sourceChainId, destChainId, token, sender, recipient, amount, nonce)`; `processed[messageId] = true` после выпуска.
- **Релэйер (off‑chain)**: слушает `TransferInitiated` в сети A, вызывает `receiveFromChain(...)` в сети B.
