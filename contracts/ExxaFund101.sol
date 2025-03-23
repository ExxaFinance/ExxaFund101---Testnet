// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Core fund contract for Exxa Finance's Top 10 portfolio, auto-investing on deposit and rebalancing via TWAP strategy
import "hyperliquid-evm/contracts/interfaces/IHyperliquid.sol";
import "./rebalancinglib.sol";

contract ExxaFund101 {
    using RebalancingLib for RebalancingLib.FundState;

    // --- Admin & Token Configuration ---
    address public owner;
    address public exxaToken;
    address public nativeToken;
    address public irtToken;
    address[] public stablecoins;

    IHyperliquid public hyperliquid;
    RebalancingLib.FundState internal fundState;

    uint256 public totalShares;
    uint256 public totalFundValueUSD;

    // --- Asset Market Data ---
    mapping(address => uint256) public assetPrices;
    mapping(address => uint256) public assetWeights;

    // --- User Holdings Tracking ---
    mapping(address => uint256) public userShares;
    mapping(address => UserInvestment[]) public userHistory;

    struct UserInvestment {
        uint256 timestamp;
        uint256 amountUSD;
        uint256 sharesIssued;
    }

    // --- Events ---
    event Deposited(address indexed user, address tokenIn, uint256 amountUSD, uint256 sharesIssued);
    event Withdrawal(address indexed user, uint256 amountUSD);
    event RedeemedToIRT(address indexed user, uint256 amountUSD);
    event FundValuationUpdated(uint256 totalValueUSD);
    event RebalanceRequested(address indexed executor, uint256 timestamp);
    event RebalanceExecuted(address indexed executor, uint256 timestamp);
    event TopAssetsUpdated(address[] newAssets);
    event AssetWeightsUpdated(address[] assetSymbols, uint256[] newWeights);
    event AssetPricesUpdated(address[] symbols, uint256[] prices);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    // Initialize core addresses and top assets with their weights
    constructor(
        address _exxaToken,
        address _nativeToken,
        address _irtToken,
        address[] memory _stablecoins,
        address _hyperliquid,
        address[] memory assets,
        uint256[] memory weights
    ) {
        require(assets.length == weights.length, "Asset/weight mismatch");
        owner = msg.sender;
        exxaToken = _exxaToken;
        nativeToken = _nativeToken;
        irtToken = _irtToken;
        stablecoins = _stablecoins;
        hyperliquid = IHyperliquid(_hyperliquid);

        fundState.assets = assets;
        fundState.targetWeights = weights;
    }

    // User deposits into fund, converted to USDT if needed and invested proportionally
    function deposit(address tokenIn, uint256 amountUSD) external {
        require(amountUSD > 0, "Amount must be greater than 0");
        require(isAcceptedToken(tokenIn), "Token not accepted");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountUSD);
        if (tokenIn != stablecoins[0]) {
            hyperliquid.swapToUSDT(tokenIn, amountUSD);
        }

        uint256 shares = totalShares == 0 ? amountUSD : (amountUSD * totalShares) / totalFundValueUSD;
        userShares[msg.sender] += shares;
        totalShares += shares;
        totalFundValueUSD += amountUSD;

        userHistory[msg.sender].push(UserInvestment({
            timestamp: block.timestamp,
            amountUSD: amountUSD,
            sharesIssued: shares
        }));

        emit Deposited(msg.sender, tokenIn, amountUSD, shares);
        _autoInvest(amountUSD);
    }

    // Automatically invest new funds proportionally across target-weighted assets
    function _autoInvest(uint256 totalAmountUSD) internal {
        for (uint i = 0; i < fundState.assets.length; i++) {
            uint256 allocation = (fundState.targetWeights[i] * totalAmountUSD) / 10000;
            hyperliquid.marketBuySymbol(fundState.assets[i], allocation);
        }
    }

    // Withdraw a portion of user's shares in exchange for a supported token
    function withdraw(uint256 shares, address tokenOut) external {
        require(userShares[msg.sender] >= shares, "Not enough shares");
        require(isAcceptedToken(tokenOut), "Invalid token");

        uint256 amountUSD = (shares * totalFundValueUSD) / totalShares;
        userShares[msg.sender] -= shares;
        totalShares -= shares;
        totalFundValueUSD -= amountUSD;

        IERC20(tokenOut).transfer(msg.sender, amountUSD);
        emit Withdrawal(msg.sender, amountUSD);
    }

    // Redeem shares for IRT token to migrate to another Exxa fund
    function redeemToIRT(uint256 shares) external {
        require(userShares[msg.sender] >= shares, "Not enough shares to convert to IRT");
        uint256 amountUSD = (shares * totalFundValueUSD) / totalShares;

        userShares[msg.sender] -= shares;
        totalShares -= shares;
        totalFundValueUSD -= amountUSD;

        IERC20(irtToken).transfer(msg.sender, amountUSD);
        emit RedeemedToIRT(msg.sender, amountUSD);
    }

    // Manually update the fund valuation in USD
    function updateFundValuation(uint256 newTotalValueUSD) external onlyOwner {
        totalFundValueUSD = newTotalValueUSD;
        emit FundValuationUpdated(newTotalValueUSD);
    }

    // Replace all 10 top assets and reset their target weights
    function updateTopAssetsAndWeights(address[] calldata newAssets, uint256[] calldata newWeights) external onlyOwner {
        require(newAssets.length == 10 && newWeights.length == 10, "Invalid length");
        fundState.assets = newAssets;
        fundState.targetWeights = newWeights;
        emit TopAssetsUpdated(newAssets);
        emit AssetWeightsUpdated(newAssets, newWeights);
    }

    // Update weights for current top assets
    function updateAssetWeights(address[] calldata assetSymbols, uint256[] calldata newWeights) external onlyOwner {
        require(assetSymbols.length == newWeights.length, "Mismatched lengths");
        fundState.targetWeights = newWeights;
        emit AssetWeightsUpdated(assetSymbols, newWeights);
    }

    // Feed price data for portfolio valuation and rebalancing
    function updateAssetPrices(address[] calldata symbols, uint256[] calldata prices) external onlyOwner {
        require(symbols.length == prices.length, "Mismatched inputs");
        for (uint i = 0; i < symbols.length; i++) {
            assetPrices[symbols[i]] = prices[i];
        }
        emit AssetPricesUpdated(symbols, prices);
    }

    // Get portfolio-wide weighted price
    function getWeightedAssetPriceSum() external view returns (uint256 totalWeightedPrice) {
        for (uint i = 0; i < fundState.assets.length; i++) {
            totalWeightedPrice += (assetPrices[fundState.assets[i]] * fundState.targetWeights[i]) / 10000;
        }
    }

    // Full rebalancing logic: adjusts assets to stay within 10% ±1% target tolerance
    function rebalancePortfolio() external onlyOwner {
        uint256 total;
        uint256[] memory currentValues = new uint256[](fundState.assets.length);

        for (uint i = 0; i < fundState.assets.length; i++) {
            uint256 value = (assetPrices[fundState.assets[i]] * fundState.targetWeights[i]) / 10000;
            currentValues[i] = value;
            total += value;
        }

        for (uint i = 0; i < fundState.assets.length; i++) {
            uint256 target = (total * fundState.targetWeights[i]) / 10000;
            uint256 current = currentValues[i];
            if (current > target * 101 / 100) {
                uint256 excess = current - target;
                hyperliquid.marketSellPartialSymbol(fundState.assets[i], excess);
            } else if (current < target * 99 / 100) {
                uint256 shortfall = target - current;
                hyperliquid.marketBuySymbol(fundState.assets[i], shortfall);
            }
        }
    }

    // Step-by-step TWAP rebalance triggered externally (e.g. via Python script)
    function rebalanceStep(uint256[] calldata prices) external onlyOwner {
        require(prices.length == fundState.targetWeights.length, "Mismatched array length");
        emit RebalanceRequested(msg.sender, block.timestamp);
        fundState.performTWAPStep(prices);
        emit RebalanceExecuted(msg.sender, block.timestamp);
    }

    // Get estimated USD value of a user's shares
    function getUserShareValue(address user) external view returns (uint256) {
        return (userShares[user] * totalFundValueUSD) / totalShares;
    }

    // Return the full asset list and current weights
    function getCurrentState() external view returns (address[] memory, uint256[] memory) {
        return (fundState.assets, fundState.targetWeights);
    }

    // Check if the token is allowed for deposits/withdrawals
    function isAcceptedToken(address token) public view returns (bool) {
        if (token == exxaToken || token == nativeToken || token == irtToken) return true;
        for (uint i = 0; i < stablecoins.length; i++) {
            if (token == stablecoins[i]) return true;
        }
        return false;
    }
}

// Basic ERC20 interface
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// Hyperliquid trading interface
interface IHyperliquid {
    function marketBuySymbol(address asset, uint256 amountUSD) external;
    function marketSellSymbol(address asset) external;
    function marketSellPartialSymbol(address asset, uint256 amountUSD) external;
    function swapToUSDT(address tokenIn, uint256 amountIn) external;
}
