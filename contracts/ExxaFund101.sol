// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "hyperliquid-evm/contracts/interfaces/IHyperliquid.sol";
import "./rebalancinglib.sol";

contract ExxaFund101 {
    using RebalancingLib for RebalancingLib.FundState;

    // === Core Admin and Token Configuration ===
    address public owner;
    address public exxaToken;
    address public nativeToken;
    address public irtToken;
    address[] public stablecoins;

    IHyperliquid public hyperliquid;
    RebalancingLib.FundState internal fundState;

    uint256 public totalShares;
    uint256 public totalFundValueUSD;

    // === Asset Valuation ===
    mapping(address => uint256) public assetPrices;
    mapping(address => uint256) public assetWeights;

    // === User Tracking ===
    mapping(address => uint256) public userShares;
    mapping(address => UserInvestment[]) public userHistory;

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
    event RebalanceRequested(address indexed executor, uint256 timestamp);
    event RebalanceExecuted(address indexed executor, uint256 timestamp);
    event TopAssetsUpdated(address[] newAssets);
    event AssetWeightsUpdated(address[] assetSymbols, uint256[] newWeights);
    event AssetPricesUpdated(address[] symbols, uint256[] prices);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

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

    function _autoInvest(uint256 totalAmountUSD) internal {
        for (uint i = 0; i < fundState.assets.length; i++) {
            uint256 allocation = (fundState.targetWeights[i] * totalAmountUSD) / 10000;
            hyperliquid.marketBuySymbol(fundState.assets[i], allocation);
        }
    }

    function sellAllAssets() external onlyOwner {
        for (uint i = 0; i < fundState.assets.length; i++) {
            hyperliquid.marketSellSymbol(fundState.assets[i]);
        }
    }

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

    function redeemToIRT(uint256 shares) external {
        require(userShares[msg.sender] >= shares, "Not enough shares to convert to IRT");
        uint256 amountUSD = (shares * totalFundValueUSD) / totalShares;

        userShares[msg.sender] -= shares;
        totalShares -= shares;
        totalFundValueUSD -= amountUSD;

        IERC20(irtToken).transfer(msg.sender, amountUSD);
        emit RedeemedToIRT(msg.sender, amountUSD);
    }

    function updateFundValuation(uint256 newTotalValueUSD) external onlyOwner {
        totalFundValueUSD = newTotalValueUSD;
        emit FundValuationUpdated(newTotalValueUSD);
    }

    function updateTopAssetsAndWeights(address[] calldata newAssets, uint256[] calldata newWeights) external onlyOwner {
        require(newAssets.length == 10 && newWeights.length == 10, "Invalid length");
        fundState.assets = newAssets;
        fundState.targetWeights = newWeights;
        emit TopAssetsUpdated(newAssets);
        emit AssetWeightsUpdated(newAssets, newWeights);
    }

    function updateAssetWeights(address[] calldata assetSymbols, uint256[] calldata newWeights) external onlyOwner {
        require(assetSymbols.length == newWeights.length, "Mismatched lengths");
        fundState.targetWeights = newWeights;
        emit AssetWeightsUpdated(assetSymbols, newWeights);
    }

    function updateAssetPrices(address[] calldata symbols, uint256[] calldata prices) external onlyOwner {
        require(symbols.length == prices.length, "Mismatched inputs");
        for (uint i = 0; i < symbols.length; i++) {
            assetPrices[symbols[i]] = prices[i];
        }
        emit AssetPricesUpdated(symbols, prices);
    }

    function getWeightedAssetPriceSum() external view returns (uint256 totalWeightedPrice) {
        for (uint i = 0; i < fundState.assets.length; i++) {
            totalWeightedPrice += (assetPrices[fundState.assets[i]] * fundState.targetWeights[i]) / 10000;
        }
    }

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

    function rebalanceStep(uint256[] calldata prices) external onlyOwner {
        require(prices.length == fundState.targetWeights.length, "Mismatched array length");
        emit RebalanceRequested(msg.sender, block.timestamp);
        fundState.performTWAPStep(prices);
        emit RebalanceExecuted(msg.sender, block.timestamp);
    }

    function getUserShareValue(address user) external view returns (uint256) {
        return (userShares[user] * totalFundValueUSD) / totalShares;
    }

    function getCurrentState() external view returns (address[] memory, uint256[] memory) {
        return (fundState.assets, fundState.targetWeights);
    }

    function isAcceptedToken(address token) public view returns (bool) {
        if (token == exxaToken || token == nativeToken || token == irtToken) return true;
        for (uint i = 0; i < stablecoins.length; i++) {
            if (token == stablecoins[i]) return true;
        }
        return false;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IHyperliquid {
    function marketBuySymbol(address asset, uint256 amountUSD) external;
    function marketSellSymbol(address asset) external;
    function marketSellPartialSymbol(address asset, uint256 amountUSD) external;
    function swapToUSDT(address tokenIn, uint256 amountIn) external;
}
