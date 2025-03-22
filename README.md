# ExxaFund101 – v1.0 Smart Contract for Exxa Finance Top 10 Fund

**ExxaFund101.sol** is the official smart contract developed by **Exxa Finance** to manage an automated portfolio based on the top 10 cryptocurrencies.  
It is designed to operate on the **Hyperliquid EVM blockchain (Testnet)**, featuring auto-investment logic, user tracking, and dynamic rebalancing.

📌 **Version**: v1.0 – Stable & compilable  
🧪 **Network**: Hyperliquid Testnet  
🔒 **Access**: Proprietary code – public for informational purposes only

---

## 🚀 Key Features

- Accepts deposits in **multiple stablecoins** (USDT, USDC...) and **EXXA token**
- Automatically invests across the **top 10 crypto assets** (by cap & volume)
- Dynamic **rebalancing** with ±0.1% tolerance from target weights
- Redeemable in **IRT token** to migrate to other Exxa funds
- Tracks full **investment history per user**
- Admin-only controls for:
  - Updating prices
  - Updating top 10 asset list
  - Adjusting asset weightings
  - Rebalancing the portfolio

---

## 🛠 Technical Overview

| Item                  | Detail |
|------------------------|--------|
| ⚙ Solidity Version     | `^0.8.20` |
| 📄 Main Contract File  | `ExxaFund101.sol` |
| 🔌 DEX Integration     | `IHyperliquid` interface (`hyperliquid-evm`) |
| 📊 Allocation Weights  | Basis points (`1000 = 10%`) |
| 🔐 Admin Access        | `onlyOwner` enforced |
| 🧩 Design              | Modular & future-proof |

---

## 🧠 How It Works

1. **Deposit**: Users can deposit supported stablecoins or EXXA.
2. **Conversion**: If needed, stablecoins are converted to USDT.
3. **Auto-Invest**: Funds are automatically split among the top 10 assets using `marketBuy()`.
4. **Rebalancing**: `rebalancePortfolio()` compares current vs. target values, and calls `marketSellPartial()` or `marketBuy()` accordingly.
5. **Withdrawals**: Users can withdraw directly or convert to IRT to jump to another fund.
6. **Admin Tools**: Owner can adjust the fund’s structure, valuation, and strategies.

---

## 🧪 Testnet Status

This contract is currently in development and testing for the **Hyperliquid Testnet**:

🔗 [Hyperliquid Testnet RPC](https://rpc.hyperliquid-testnet.xyz/evm)

You can deploy and interact with it via:

- Hardhat or Foundry
- Python deployment script using `web3.py` and `hyperliquid-evm`

---

## 📌 Next Versions (v1.1+)

- [ ] Oracle price feeds (e.g., Chainlink or native Hyperliquid data)
- [ ] Frontend UI (React-based investor dashboard)
- [ ] Automated timed rebalancing
- [ ] Modular fund types (Crypto / Narrative / TradFi variations)
- [ ] On-chain metadata for tokenized funds

---

## ⚠️ License & Ownership

📎 This smart contract is the **exclusive intellectual property of Exxa Finance**.  
It is made **public solely for informational and transparency purposes**.

🚫 **This project is not open-source.**  
Any commercial use, reproduction, or fork is strictly prohibited without written permission from Exxa Finance.

---

## 📬 Contact

🔗 Website: [exxafinance.com](https://exxafinance.com)  
📩 Email: Soon available.  
📌 Version: `ExxaFund101.sol` v1.0 (Testnet)

---

> Thank you for your interest in Exxa. Together, we’re building the future of smart, automated crypto investing. 🌐🚀
