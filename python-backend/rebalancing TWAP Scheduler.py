import time
from web3 import Web3
from eth_account import Account
from dotenv import load_dotenv
import os

# Load environment variables
load_dotenv()

# ========== CONFIGURATION ==========
RPC_URL = "https://rpc.hyperliquid-testnet.xyz/evm"
PRIVATE_KEY = os.getenv("PRIVATE_KEY")
CONTRACT_ADDRESS = "0xYourExxaFund101ContractAddress"
ABI_PATH = "./abi/ExxaFund101.json"  # JSON ABI from compiled contract
GAS_LIMIT = 1_500_000
SECONDS_BETWEEN_STEPS = 24 * 3600  # one day
# ===================================

# Setup web3 connection
w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = Account.from_key(PRIVATE_KEY)
w3.eth.default_account = account.address

# Load contract ABI
import json
with open(ABI_PATH) as f:
    abi = json.load(f)

contract = w3.eth.contract(address=Web3.to_checksum_address(CONTRACT_ADDRESS), abi=abi)

# Rebalance loop
def execute_twap_rebalance():
    for i in range(10):
        print(f"Executing TWAP rebalance step {i + 1}/10...")

        nonce = w3.eth.get_transaction_count(account.address)
        tx = contract.functions.rebalanceTWAPStep().build_transaction({
            'from': account.address,
            'nonce': nonce,
            'gas': GAS_LIMIT,
            'gasPrice': w3.eth.gas_price
        })

        signed_tx = w3.eth.account.sign_transaction(tx, private_key=PRIVATE_KEY)
        tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)

        receipt = w3.eth.wait_for_transaction_receipt(tx_hash)
        print(f"✅ Step {i + 1} executed: {tx_hash.hex()}")
        print(f"⏳ Waiting {SECONDS_BETWEEN_STEPS} seconds before next step...\n")

        time.sleep(SECONDS_BETWEEN_STEPS)

# Launch scheduler
if __name__ == "__main__":
    print("🚀 Starting Exxa TWAP rebalance automation (10 steps)")
    execute_twap_rebalance()
