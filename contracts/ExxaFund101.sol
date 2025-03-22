// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import Hyperliquid EVM interface
import "hyperliquid-evm/contracts/interfaces/IHyperliquid.sol";

/**
 * @title ExxaTop10Fund
 * @dev A decentralized smart contract that manages a diversified Top 10 crypto portfolio.
 * Funds are automatically invested via Hyperliquid DEX, with optional IRT token redemption,
 * asset price tracking, and dynamic rebalancing to maintain fund stability.
 */
contract ExxaTop10Fund {
    // === Core Admin and Token Configuration ===
    address public owner;                       // Contract owner with admin rights
    uint256 public totalShares;                 // Total fund shares issued
    uint256 public totalFundValueUSD;           // Total fund value in USD (basis for share valuation)

    address public exxaToken;                   // Exxa utility/governance token
    address public nativeToken;                 // Blockchain native token (e.g. ETH)
    address public irtToken;                    // Intermediate token to jump between funds
    address[] public stablecoins;               // Accepted stablecoins for deposits

    IHyperliquid public hyperliquid;            // Interface to interact with Hyperliquid

    // === Fund Portfolio Data ===
    string[] public top10Assets;                // Top 10 crypto assets (symbols like "BTC")
    mapping(string => uint256) public assetWeights;  // Allocation weights in basis points (e.g. 1000 = 10%)
    mapping(string => uint256) public assetPrices;   // Manually updated asset prices for rebalancing

    // === User Tracking ===
    mapping(address => uint256) public userShares;   // User share balances
    mapping(address => UserInvestment[]) public userHistory; // User historical investment records

    // === Struct to store user deposits ===
    struct UserInvestment {
        uint256 timestamp;
        uint256 amountUSD;
        uint256 sharesIssued;
    }

    // === Events ===
    event Deposited(address indexed user, address tokenIn, uint256 amountUSD, uint256 sharesIssued);
    event Withdrawal(address indexed user, uint256 amountUSD);
    event RedeemedToIRT(address indexed user, uint256 amountUSD);
    event FundValuationUpdated(uint256 totalValueUSD);
    event TopAssetsUpdated(string[] newAssets);
    event AssetWeightsUpdated(string[] assetSymbols, uint256[] newWeights);
    event AssetPricesUpdated(string[] symbols, uint256[] prices);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /**
     * @notice Constructor sets token references, stablecoins and default portfolio composition
     */
    constructor(
        address _exxaToken,
        address _nativeToken,
        address _irtToken,
        address[] memory _stablecoins,
        address _hyperliquid
    ) {
        owner = msg.sender;
        exxaToken = _exxaToken;
        nativeToken = _nativeToken;
        irtToken = _irtToken;
        stablecoins = _stablecoins;
        hyperliquid = IHyperliquid(_hyperliquid);

        // Initial Top 10 assets
        top10Assets = [
            "BTC", "ETH", "XRP", "BNB", "SOL",
            "ADA", "LINK", "TRX", "EXXA", "EXXA"
        ];

        // Set default allocation to 10% each
        for (uint8 i = 0; i < top10Assets.length; i++) {
            assetWeights[top10Assets[i]] = 1000;
        }
    }

    /**
     * @notice Deposit stablecoin or native token to join the fund
     */
    function deposit(address tokenIn, uint256 amountUSD) external {
        require(amountUSD > 0, "Amount must be greater than 0");
        require(isAcceptedToken(tokenIn), "Token not accepted");

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountUSD);

        // Convert to USDT if necessary
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

    /**
     * @dev Internal: Invest funds proportionally to asset weights
     */
    function _autoInvest(uint256 totalAmountUSD) internal {
        require(top10Assets.length == 10, "Top 10 not initialized");
        for (uint i = 0; i < top10Assets.length; i++) {
            string memory asset = top10Assets[i];
            uint256 allocation = (assetWeights[asset] * totalAmountUSD) / 10000;
            hyperliquid.marketBuy(asset, allocation);
        }
    }

    /**
     * @notice Full liquidation of the fund (emergency only)
     */
    function sellAllAssets() external onlyOwner {
        for (uint i = 0; i < top10Assets.length; i++) {
            hyperliquid.marketSell(top10Assets[i]);
        }
    }

    /**
     * @notice Withdraw user shares for a supported token
     */
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

    /**
     * @notice Redeem shares for IRT token to move to another fund
     */
    function redeemToIRT(uint256 shares) external {
        require(userShares[msg.sender] >= shares, "Not enough shares to convert to IRT");
        uint256 amountUSD = (shares * totalFundValueUSD) / totalShares;

        userShares[msg.sender] -= shares;
        totalShares -= shares;
        totalFundValueUSD -= amountUSD;

        IERC20(irtToken).transfer(msg.sender, amountUSD);
        emit RedeemedToIRT(msg.sender, amountUSD);
    }

    /** Update total valuation manually or from oracle */
    function updateFundValuation(uint256 newTotalValueUSD) external onlyOwner {
        totalFundValueUSD = newTotalValueUSD;
        emit FundValuationUpdated(newTotalValueUSD);
    }

    /** Replace all Top 10 assets and their weights */
    function updateTopAssetsAndWeights(string[] calldata newAssets, uint256[] calldata newWeights) external onlyOwner {
        require(newAssets.length == 10 && newWeights.length == 10, "Invalid length");
        delete top10Assets;
        for (uint i = 0; i < 10; i++) {
            top10Assets.push(newAssets[i]);
            assetWeights[newAssets[i]] = newWeights[i];
        }
        emit TopAssetsUpdated(newAssets);
        emit AssetWeightsUpdated(newAssets, newWeights);
    }

    /** Update individual asset weights */
    function updateAssetWeights(string[] calldata assetSymbols, uint256[] calldata newWeights) external onlyOwner {
        require(assetSymbols.length == newWeights.length, "Mismatched lengths");
        for (uint i = 0; i < assetSymbols.length; i++) {
            assetWeights[assetSymbols[i]] = newWeights[i];
        }
        emit AssetWeightsUpdated(assetSymbols, newWeights);
    }

    /** Update asset prices (used in rebalancing) */
    function updateAssetPrices(string[] calldata symbols, uint256[] calldata prices) external onlyOwner {
        require(symbols.length == prices.length, "Mismatched inputs");
        for (uint i = 0; i < symbols.length; i++) {
            assetPrices[symbols[i]] = prices[i];
        }
        emit AssetPricesUpdated(symbols, prices);
    }

    /** Calculate weighted average price across all assets */
    function getWeightedAssetPriceSum() external view returns (uint256 totalWeightedPrice) {
        for (uint i = 0; i < top10Assets.length; i++) {
            totalWeightedPrice += (assetPrices[top10Assets[i]] * assetWeights[top10Assets[i]]) / 10000;
        }
    }

    /**
     * @notice Rebalance fund by adjusting only overweight or underweight assets
     * Tolerance: 10% +/- 0.1% (bounds: 990 - 1010)
     */
    function rebalancePortfolio() external onlyOwner {
        uint256 portfolioTotal;
        mapping(string => uint256) storage currentValues;

        for (uint i = 0; i < top10Assets.length; i++) {
            string memory asset = top10Assets[i];
            uint256 value = (assetPrices[asset] * assetWeights[asset]) / 10000;
            currentValues[asset] = value;
            portfolioTotal += value;
        }

        uint256 lower = 990;
        uint256 upper = 1010;

        for (uint i = 0; i < top10Assets.length; i++) {
            string memory asset = top10Assets[i];
            uint256 target = (portfolioTotal * assetWeights[asset]) / 10000;
            uint256 current = currentValues[asset];

            if (current > (target * upper) / 1000) {
                uint256 excess = current - target;
                hyperliquid.marketSellPartial(asset, excess);
            } else if (current < (target * lower) / 1000) {
                uint256 shortfall = target - current;
                hyperliquid.marketBuy(asset, shortfall);
            }
        }
    }

    /** Check if token is valid */
    function isAcceptedToken(address token) public view returns (bool) {
        if (token == exxaToken || token == nativeToken || token == irtToken) return true;
        for (uint i = 0; i < stablecoins.length; i++) {
            if (token == stablecoins[i]) return true;
        }
        return false;
    }

    /** View user's current share value */
    function getUserShareValue(address user) external view returns (uint256) {
        return (userShares[user] * totalFundValueUSD) / totalShares;
    }

    function getStablecoins() external view returns (address[] memory) {
        return stablecoins;
    }

    function getTop10Assets() external view returns (string[] memory) {
        return top10Assets;
    }

    function getUserHistory(address user) external view returns (UserInvestment[] memory) {
        return userHistory[user];
    }
}

/**
 * @dev Interface for ERC20 tokens
 */
interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

/**
 * @dev Interface for Hyperliquid interaction
 */
interface IHyperliquid {
    function marketBuy(string calldata assetSymbol, uint256 amountUSD) external;
    function marketSell(string calldata assetSymbol) external;
    function marketSellPartial(string calldata assetSymbol, uint256 amountUSD) external;
    function swapToUSDT(address tokenIn, uint256 amountIn) external;
}
