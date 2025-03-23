# 🧠 ExxaFund101 – HyperEVM Smart Contracts (v1.0)

This directory contains the complete set of low-level smart contracts built to interact with the **Hyperliquid EVM** system.  
These contracts are deployed in the context of the **Exxa Finance** ecosystem and play critical roles in L1 data access, event-based L1 interactions, and liquidity management.

> 🚧 Testnet integration is under active refinement  
> 🔐 Not open-source — made public solely for transparency and interoperability

---

## 📂 Contracts Overview

| Contract                 | Type     | Purpose                                                  |
|--------------------------|----------|-----------------------------------------------------------|
| `L1Read.sol`             | Utility  | Read-only access to Hyperliquid’s L1 precompiles          |
| `L1Write.sol`            | Utility  | Emits event-based intents recognized by Hyperliquid L1    |
| `liquidityhelper.sol`    | Library  | LP management functions for any token pair                |
| `liquidityproxy.sol`     | Contract | Controlled liquidity provisioning for wZNN/wETH pair only |

---

## 🔍 Detailed Functionality per Contract

---

### 📘 `L1Read.sol`

This contract allows **any EVM-compatible contract** to query real-time data from **Hyperliquid’s native L1 system** via special precompile addresses.

#### 🔹 Structs

- `Position`: Contains size, leverage, and entry value of a perpetual position
- `SpotBalance`: Tracks total spot token balance, hold amount, and entry value
- `UserVaultEquity`: Total vault equity and lock time
- `Withdrawable`: Amount withdrawable from system
- `Delegation`: Represents a delegation to a validator
- `DelegatorSummary`: Summary of total delegated/undelegated/pending withdrawal

#### 🔹 Precompile Addresses

| Name                   | Address               |
|------------------------|------------------------|
| `POSITION_PRECOMPILE_ADDRESS`        | `0x...0800` |
| `SPOT_BALANCE_PRECOMPILE_ADDRESS`    | `0x...0801` |
| `VAULT_EQUITY_PRECOMPILE_ADDRESS`    | `0x...0802` |
| `WITHDRAWABLE_PRECOMPILE_ADDRESS`    | `0x...0803` |
| `DELEGATIONS_PRECOMPILE_ADDRESS`     | `0x...0804` |
| `DELEGATOR_SUMMARY_PRECOMPILE_ADDRESS`| `0x...0805` |
| `MARK_PX_PRECOMPILE_ADDRESS`         | `0x...0806` |
| `ORACLE_PX_PRECOMPILE_ADDRESS`       | `0x...0807` |
| `SPOT_PX_PRECOMPILE_ADDRESS`         | `0x...0808` |
| `L1_BLOCK_NUMBER_PRECOMPILE_ADDRESS` | `0x...0809` |

#### 🔹 Functions

- `position(address user, uint16 perp)` → Returns `Position`
- `spotBalance(address user, uint64 token)` → Returns `SpotBalance`
- `userVaultEquity(address user, address vault)` → Returns `UserVaultEquity`
- `withdrawable(address user)` → Returns `Withdrawable`
- `delegations(address user)` → Returns array of `Delegation`
- `delegatorSummary(address user)` → Returns `DelegatorSummary`
- `markPx(uint16 index)` → Returns latest mark price
- `oraclePx(uint16 index)` → Returns oracle price
- `spotPx(uint32 index)` → Returns spot token price
- `l1BlockNumber()` → Returns current L1 block

✅ Use Cases:
- TWAP scheduling
- Vault logic
- Live price reads for on-chain logic

---

### 📝 `L1Write.sol`

This contract **emits events** that the Hyperliquid L1 listens to for action execution. It does **not mutate state**, but acts as a **signal layer** between smart contracts and Hyperliquid's L1 engine.

#### 🔹 Events & Functions

Each function below triggers an event interpreted off-chain by Hyperliquid's system.

| Function | Event | Description |
|----------|-------|-------------|
| `sendIocOrder(uint32 asset, bool isBuy, uint64 limitPx, uint64 sz)` | `IocOrder` | Place immediate/limit market order |
| `sendVaultTransfer(address vault, bool isDeposit, uint64 usd)` | `VaultTransfer` | Move funds in/out of vaults |
| `sendTokenDelegate(address validator, uint64 _wei, bool isUndelegate)` | `TokenDelegate` | Delegate or undelegate tokens |
| `sendCDeposit(uint64 _wei)` | `CDeposit` | Deposit credit to the system |
| `sendCWithdrawal(uint64 _wei)` | `CWithdrawal` | Withdraw from system credit |
| `sendSpot(address destination, uint64 token, uint64 _wei)` | `SpotSend` | Spot transfer to user or contract |
| `sendUsdClassTransfer(uint64 ntl, bool toPerp)` | `UsdClassTransfer` | Convert funds between spot/perp class |

✅ Use Cases:
- Vault-based user triggers
- Rebalancing actions
- Delegation automation

---

### 💧 `liquidityhelper.sol`

A fully reusable **Solidity library** for managing LP positions via any **UniswapV2-compatible router**.

#### 🔹 Key Functions

```solidity
addLiquidity(
  address router,
  address tokenA,
  address tokenB,
  uint256 amountADesired,
  uint256 amountBDesired,
  uint256 amountAMin,
  uint256 amountBMin,
  address to,
  uint256 deadline
)
