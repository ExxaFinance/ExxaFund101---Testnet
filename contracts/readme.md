# 🛡️ ExxaFund101 Smart Contracts (v1.0)

This folder contains the core Solidity contracts powering the Exxa Finance protocol and its flagship product: the **Top 10 Crypto Index Fund**.

---

## 📂 Contracts

### 1. `ExxaFund101.sol`

A fully on-chain fund smart contract designed to:

- Accept deposits in Exxa token or stablecoins (USDT, USDC, DAI, etc.)
- Auto-invest funds on the Hyperliquid EVM DEX
- Distribute investments across a curated list of 10 assets
- Track each investor's shares and allocation
- Allow withdrawals in proportion to fund value
- Mint a special `IRT` token when a user chooses to transfer value to another fund
- Enable the owner to:
  - Update fund composition
  - Change asset weights
  - Trigger rebalancing
  - View fund portfolio and user info

✅ Fully upgradeable structure for future versions.

---

### 2. `RebalancingLib.sol`

A utility library imported by `ExxaFund101.sol` that handles all rebalancing logic.  
It includes:

- 🧮 Price-based delta calculations for each asset
- 🟥 Overweight / 🟩 Underweight detection
- ⚖️ Rebalancing plans that scale down excess positions and increase deficient ones
- 🔁 TWAP (Time-Weighted Average Price) support by executing trades over 10 steps
- 🔄 `scaleToMatch()` logic to rebalance precisely even with imbalanced supply/demand
- ✍️ Clean, modular code ready for reuse and testing

---

## 🚀 Technical Overview

- Language: Solidity `^0.8.20`
- Network: [Hyperliquid EVM](https://hyperliquid.xyz)
- Fund Mode: Full on-chain portfolio logic
- Access Control: `onlyOwner` modifier for fund configuration
- Tokens: Supports Exxa, USDT, USDC, DAI, and Hyperliquid native token
- Rebalancing Logic: Executed through TWAP cycles with `rebalanceTWAPStep()`

---

## 🔐 Admin Functions (Owner Only)

- `setTop10()` → Update the asset list (Top 10)
- `setWeights()` → Modify weight allocation (%)
- `rebalanceTWAPStep()` → Execute a daily rebalancing action (part of a 10-step plan)
- `resetTWAP()` → Restart TWAP cycle
- `priceOfTop10()` → Returns the current total weighted price of the fund
- `withdrawToIRT()` → Redeem position into IRT token for migration

---

## 🛠 Future Upgrades

Planned improvements include:

- 🧠 Oracle integrations for real-time price feeds (Chainlink)
- 🔬 Include volatility & trend analysis
- 📊 Performance-based fund re-weighting
- 🔁 Multiple fund types (DeFi / TradFi / Thematic categories)
- 👁 More TWAP Order (Diminish market risk)

---

## 🧪 Development & Testing

Use Hardhat or Foundry for local testing and deployment:

```bash
npm install
npx hardhat test
