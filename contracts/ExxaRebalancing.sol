// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RebalancingLib
 * @dev Library to compute rebalancing deltas for ExxaFund101 Top 10 assets.
 * This library identifies underweight and overweight assets, and computes
 * how to shift capital between them to bring allocations back to target weights.
 */
library RebalancingLib {
    using RebalancingLib for *;

    struct AssetAdjustment {
        string symbol;
        int256 deltaUSD; // Positive = Buy, Negative = Sell
    }

    /**
     * @notice Returns the current USD value of an asset given its weight and price
     */
    function getCurrentValue(
        uint256 price,
        uint256 weightBps,
        uint256 totalPortfolioUSD
    ) internal pure returns (uint256) {
        return (price * weightBps * totalPortfolioUSD) / (10000 * price);
    }

    /**
     * @notice Get the delta (buy/sell amount) needed for a single asset to reach its target weight
     * @dev Used for single-asset step-based TWAP rebalancing
     */
    function getAssetDelta(
        string memory asset,
        uint256 weight,
        uint256 price,
        string[] memory top10,
        mapping(string => uint256) storage weights,
        mapping(string => uint256) storage prices
    ) internal view returns (int256 deltaUSD, uint256 totalPortfolioUSD) {
        totalPortfolioUSD = getTotalPortfolioValue(top10, weights, prices);
        uint256 target = (totalPortfolioUSD * weight) / 10000;
        uint256 current = (price * weight) / 10000;

        // Calculate delta: difference between target and current allocation
        if (current > target) {
            deltaUSD = int256(target) - int256(current); // negative = sell
        } else {
            deltaUSD = int256(target - current); // positive = buy
        }
    }

    /**
     * @notice Get the total portfolio value based on all assets and prices
     */
    function getTotalPortfolioValue(
        string[] memory top10,
        mapping(string => uint256) storage weights,
        mapping(string => uint256) storage prices
    ) internal view returns (uint256 totalValueUSD) {
        for (uint i = 0; i < top10.length; i++) {
            string memory asset = top10[i];
            totalValueUSD += (prices[asset] * weights[asset]) / 10000;
        }
    }

    /**
     * @notice Returns two arrays of adjustments: sells and buys to balance the portfolio
     * Assets over 10% will provide liquidity to those under 10% proportionally
     */
    function computeRebalancePlan(
        string[] memory top10,
        mapping(string => uint256) storage weights,
        mapping(string => uint256) storage prices
    ) internal view returns (AssetAdjustment[] memory sells, AssetAdjustment[] memory buys) {
        uint256 totalValueUSD = getTotalPortfolioValue(top10, weights, prices);
        uint256 toleranceBps = 10; // 0.1% tolerance (10bps)

        // Temp memory arrays to hold max 10 entries
        AssetAdjustment[] memory overweights = new AssetAdjustment[](10);
        AssetAdjustment ;

        uint8 overIndex;
        uint8 underIndex;

        for (uint i = 0; i < top10.length; i++) {
            string memory asset = top10[i];
            uint256 price = prices[asset];
            uint256 target = (totalValueUSD * weights[asset]) / 10000;
            uint256 current = (price * weights[asset]) / 10000;

            if (current > target + (target * toleranceBps) / 10000) {
                overweights[overIndex++] = AssetAdjustment(asset, int256(current) - int256(target));
            } else if (current < target - (target * toleranceBps) / 10000) {
                underweights[underIndex++] = AssetAdjustment(asset, int256(target) - int256(current));
            }
        }

        sells = new AssetAdjustment[](overIndex);
        buys = new AssetAdjustment[](underIndex);

        for (uint i = 0; i < overIndex; i++) {
            sells[i] = overweights[i];
        }
        for (uint i = 0; i < underIndex; i++) {
            buys[i] = underweights[i];
        }
    }

    /**
     * @notice Sum total value of an array of AssetAdjustments
     */
    function sumAdjustments(AssetAdjustment[] memory adjustments) internal pure returns (uint256 total) {
        for (uint i = 0; i < adjustments.length; i++) {
            total += uint256(adjustments[i].deltaUSD);
        }
    }

    /**
     * @notice Normalize adjustments to ensure sells match total of buys (if needed)
     */
    function scaleToMatch(
        AssetAdjustment[] memory sellers,
        AssetAdjustment[] memory buyers
    ) internal pure returns (AssetAdjustment[] memory scaledSells, AssetAdjustment[] memory scaledBuys) {
        uint256 totalSell = sumAdjustments(sellers);
        uint256 totalBuy = sumAdjustments(buyers);

        if (totalSell == totalBuy) {
            return (sellers, buyers);
        }

        uint256 ratio = (totalSell * 1e18) / totalBuy;

        scaledBuys = new AssetAdjustment[](buyers.length);
        for (uint i = 0; i < buyers.length; i++) {
            scaledBuys[i] = AssetAdjustment({
                symbol: buyers[i].symbol,
                deltaUSD: int256((uint256(buyers[i].deltaUSD) * ratio) / 1e18)
            });
        }
        scaledSells = sellers;
    }
}
