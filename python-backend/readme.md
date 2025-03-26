# 🧠 ExxaFund101 – TWAP Rebalancing Scheduler (v1.0)

This Python script automates Time-Weighted Average Price (TWAP) rebalancing for the `ExxaFund101.sol` smart contract on the Hyperliquid EVM.

It interacts with the `rebalanceTWAPStep()` function to rebalance the fund's asset allocation gradually, one asset per transaction, over a period of several days.  
This method minimizes market impact and distributes liquidity moves evenly.

---

## 🚧 Future Improvements

This is an initial version (v1.0) and will be improved progressively to deliver more precise, intelligent rebalancing.  
Planned enhancements include:

- ⏱️ More frequent refresh cycles (10 is for test)
- 📊 Quantitative performance-based asset scoring
- 📈 Dynamic weight re-evaluation
- 🧠 More files associated with the rebalancing to come

These upgrades will allow Exxa Funds to react smartly to market conditions and maintain optimal exposure at all times.

---

## ✅ Features

- Supports Exxa's Top 10 Asset Fund
- TWAP logic: 10 rebalancing steps across time
- Hyperliquid EVM-compatible  
- Testnet version currently **under refinement**
- Works via command line, cron jobs, GitHub Actions, or backend servers
- Web3 integration with private key signing

---

## 📁 Structure


