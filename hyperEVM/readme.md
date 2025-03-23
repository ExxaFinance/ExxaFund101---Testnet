# 🧠 ExxaFund101 – HyperEVM Smart Contracts (v1.0)

This directory contains the full set of EVM-level smart contracts built to interact with the **Hyperliquid EVM** system.  
These contracts serve as a foundation for L1 data reading, emitting actionable intents, and managing liquidity within the **Exxa Finance** protocol stack.

> 🛠️ Testnet integration is currently under refinement  
> 🔐 Not open-source – public for transparency and documentation only

---

## 📂 Contracts Overview

| Contract                 | Type     | Purpose                                                  |
|--------------------------|----------|-----------------------------------------------------------|
| `L1Read.sol`             | Utility  | Read-only access to Hyperliquid’s L1 precompiles          |
| `L1Write.sol`            | Utility  | Emits event-based intents interpreted by Hyperliquid L1   |
| `liquidityhelper.sol`    | Library  | LP functions for any token pair using UniswapV2 router    |
| `liquidityproxy.sol`     | Contract | Owner-controlled LP provisioning with enforced limits     |

---

## 📘 `L1Read.sol`

Read-only utility contract for accessing **on-chain Hyperliquid L1 data** using precompile addresses.

### 📦 Structs

- `Position`: Perpetual position (size, leverage, entry)
- `SpotBalance`: Token balance & entry notional
- `UserVaultEquity`: Vault equity + lock time
- `Withdrawable`: Amount eligible for withdrawal
- `Delegation`: Delegated validator info
- `DelegatorSummary`: Delegation stats

### 🔌 Precompile Calls

| Function                         | Description                                  |
|----------------------------------|----------------------------------------------|
| `position(user, perpId)`         | Read perp positions                          |
| `spotBalance(user, tokenId)`     | View token balance                           |
| `userVaultEquity(user, vault)`   | Vault share value                            |
| `withdrawable(user)`             | Amount available to withdraw                 |
| `delegations(user)`              | All active delegations                       |
| `delegatorSummary(user)`         | Delegated / undelegated / pending values     |
| `markPx(assetId)`                | Live market price                            |
| `oraclePx(assetId)`              | Oracle-reported price                        |
| `spotPx(tokenId)`                | Spot market price                            |
| `l1BlockNumber()`                | Current Hyperliquid L1 block number          |

✅ **Used by:** rebalancing bots, vault monitoring, UI dashboards, smart strategies.

---

## 📝 `L1Write.sol`

A minimal contract to **emit Hyperliquid-compatible intent events**, which are picked up and executed by the off-chain L1 engine.

### 🔔 Event-Based Functions

| Function                              | Event Emitted         | Description                              |
|---------------------------------------|------------------------|------------------------------------------|
| `sendIocOrder(...)`                   | `IocOrder`             | Submit market or limit order             |
| `sendVaultTransfer(...)`             | `VaultTransfer`        | Deposit or withdraw into vaults          |
| `sendTokenDelegate(...)`             | `TokenDelegate`        | Delegate/undelegate to a validator       |
| `sendCDeposit(...)`                  | `CDeposit`             | Add capital to credit pool               |
| `sendCWithdrawal(...)`               | `CWithdrawal`          | Withdraw from credit system              |
| `sendSpot(...)`                      | `SpotSend`             | Transfer tokens between users            |
| `sendUsdClassTransfer(...)`         | `UsdClassTransfer`     | Move assets between spot/perp systems    |

✅ **Used by:** smart contract vaults, rebalancing triggers, automation bots.

---

## 💧 `liquidityhelper.sol`

A Solidity library offering plug-and-play LP provisioning for **any UniswapV2-compatible DEX router**.

### 🔧 Library Methods

```solidity
addLiquidity(
  router, tokenA, tokenB,
  amountADesired, amountBDesired,
  amountAMin, amountBMin,
  to, deadline
)

addLiquidityETH(
  router, token,
  amountTokenDesired,
  amountTokenMin, amountETHMin,
  to, deadline
)
