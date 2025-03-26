# ExxaFund101 – v1.0 Smart Contract for Exxa Finance Top 10 Fund

**ExxaFund101.sol** is the official smart contract developed by **Exxa Finance** to manage an automated portfolio based on the top 10 cryptocurrencies.  
It is designed to operate on the **Hyperliquid EVM blockchain (Testnet)**, featuring auto-investment logic, user tracking, modular rebalancing, and backend automation tools.

📌 **Version**: v1.0 – Stable & compilable  
🧪 **Network**: Hyperliquid Testnet  
🔒 **Access**: Proprietary code – public for informational purposes only

---

## 🔍 Overview
This repository includes the entire infrastructure for managing the Exxa Top 10 Fund:
- Smart contracts for deposits, portfolio management, withdrawals, and IRT token migration
- A modular Solidity library for rebalancing logic
- A Python automation script for TWAP execution across multiple days
- Deployment scripts for testnet integration via Ethers and Web3

> ⚠️ This project is **not open-source**. It is made **public for documentation and transparency only**, and remains the intellectual property of **Exxa Finance**.

---

## 🚀 Key Features

- Accepts deposits in **multiple stablecoins** (USDT, USDC...) and **EXXA token**
- Automatically invests across the **top 10 crypto assets** (by market cap & volume)
- Smart contract uses `marketBuy()` and `marketSellPartial()` via **Hyperliquid EVM DEX integration**
- Dynamic **rebalancing** logic with ±0.1% tolerance from target weights
- Rebalancing executed through **TWAP logic** over 10 steps
- Redeemable in **IRT token** to migrate funds between Exxa fund products
- Tracks full **investment history per user**
- Admin-only controls for:
  - Updating top 10 asset list
  - Adjusting per-asset weights
  - Forcing price updates (manual or oracle)
  - Calling rebalancing steps

---

## 📦 Project Structure

- **`ExxaFund101.sol`** – Core contract managing deposits, swaps, rebalancing, redemptions
- **`RebalancingLib.sol`** – Dedicated library to handle weight deviations and rebalancing math
- **`/contracts/`** – Compiled Solidity artifacts and metadata
- **`/scripts/`** – Deployment via `ethers.js` or `web3.js`
- **`/Backend/rebalance_TWAP_scheduler.py`** – Python script to automate 10-day rebalancing
- **`/abi/ExxaFund101.json`** – Compiled ABI for frontend/backend interactions

---

## 🧠 How It Works

1. **Deposit**: Users deposit supported stablecoins or EXXA.
2. **Conversion**: Stablecoins (non-USDT) are converted to USDT on-chain.
3. **Auto-Invest**: Funds are split across the top 10 assets using target weights.
4. **Rebalancing**: The system detects over-/underweight assets and gradually rebalances via TWAP.
5. **Withdrawals**: Users can withdraw in tokens or mint IRT to migrate to another fund.
6. **Admin Tools**: Enable weight config, asset list updates, price overrides, and reset of TWAP.

---

## 🛠 Technical Overview

| Item                  | Detail |
|------------------------|--------|
| ⚙ Solidity Version     | `^0.8.20` |
| 📄 Main Contract File  | `ExxaFund101.sol` |
| 🔌 DEX Integration     | `IHyperliquid` interface (`hyperliquid-evm`) |
| 📊 Allocation Weights  | Basis points (`1000 = 10%`) |
| 🔐 Admin Access        | `onlyOwner` enforced |
| 🧩 Design              | Modular & upgrade-ready |

---

## 📂 TWAP Rebalancing Automation

A 10-step TWAP strategy is implemented using:

**Python Script** → `/Backend/rebalance_TWAP_scheduler.py`

- Runs 1 step of rebalancing via `rebalanceTWAPStep()` every 24h
- Designed for use with cron, CI/CD, or backend automation
- `.env` support for secure private key handling
- Waits between steps automatically (default = 1 day)

### Installation
```bash
pip install web3 python-dotenv
```

### Example Usage
```bash
python Backend/rebalance_TWAP_scheduler.py
```

---

## 🧪 Testnet Deployment

The ExxaFund101 system is currently available for testing on **Hyperliquid Testnet**:

🔗 [Testnet RPC][(https://rpc.hyperliquid-testnet.xyz/evm](https://chainlist.org/chain/998))

- Deploy via:
  - Hardhat / Foundry
  - `/scripts/deploy_with_ethers.ts`
  - `/scripts/deploy_with_web3.ts`

---

## 📈 Roadmap – Next Versions (v1.1+)

- [ ] Oracle price feeds (e.g., Chainlink or Hyperliquid-native)
- [ ] Web frontend for deposits, history & withdrawals (React)
- [ ] Keeper-automated rebalancing
- [ ] Additional fund types (DeFi, RWA, AI, TradFi)
- [ ] NFT/IRT Metadata standard

---

## ⚠️ License & Ownership

📎 This smart contract is the **exclusive intellectual property of Exxa Finance**.  
It is made **public solely for informational and transparency purposes**.

🚫 **This project is not open-source.**  
Any commercial use, reproduction, or fork is strictly prohibited without written permission from Exxa Finance.

---

## 📬 Contact

🔗 Website: [exxafinance.com](https://exxafinance.com)  

📩 Twitter: [See Twitter](https://x.com/exxafinance) 

🧑‍💼 Partnerships: [See Telegram](https://t.me/exxafinance)

---

> Thank you for your interest in Exxa Finance. Together, we’re building the future of smart, automated crypto investing. 🌐🚀
