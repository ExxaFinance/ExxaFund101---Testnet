# 🧩 ExxaFund101 – Smart Contract Artifacts

This folder contains the compiled artifacts generated from the ExxaFund101 Solidity smart contracts.  
These files are essential for interacting with the contracts from Python, JavaScript, or backend scripts.

---

## 📦 Contents

| File                        | Description                                               |
|-----------------------------|-----------------------------------------------------------|
| `ExxaFund101.json`          | ABI & bytecode for the ExxaFund101 main contract          |
| `ExxaTop10Fund_metadata.json` | Metadata for frontend indexing and contract labeling    |
| `IERC20.json`               | Standard ERC-20 interface (used for token interaction)    |
| `IERC20_metadata.json`      | Metadata for ERC-20 interface                             |
| `build-info/`               | Hardhat/Foundry internal build data                       |

---

## 🧠 What Are Artifacts?

- `.json` files generated after compilation
- Include:
  - ABI (Application Binary Interface)
  - Bytecode (for deployment)
  - Compiler version and metadata
- Used by:
  - Frontend apps (React / web3.js / ethers.js)
  - Python scripts (e.g., `rebalance_scheduler.py`)
  - Test automation and deployments

---

## ⚙️ How to Generate

Artifacts are typically created by:

```bash
npx hardhat compile
