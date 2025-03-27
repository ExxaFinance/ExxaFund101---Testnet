// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * RebalancingLib helps the ExxaFund101 contract figure out how to bring
 * the portfolio back to its target allocations.
 *
 * It checks which assets have grown too large (overweight) or too small (underweight),
 * and calculates how much to buy or sell to fix that.
 * 
 * Future dev: Rebalancing will have more refresh for smooth portfolio adjustments.
 */
library RebalancingLib {
    // Each AssetAdjustment tells us how much to buy or sell of a token.
    // If deltaUSD is positive, we need to buy. If it's negative, we should sell.
    struct AssetAdjustment {
        string symbol;
        int256 deltaUSD;
    }

    // Calculates how much value (in USD) an asset currently has in the portfolio.
    function getCurrentValue(
        uint256 price,
        uint256 weightBps,
        uint256 totalPortfolioUSD
    ) internal pure returns (uint256) {
        return (price * weightBps * totalPortfolioUSD) / (10000 * price);
    }

    // Figures out how far an asset is from its target weight in USD.
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

        if (current > target) {
            deltaUSD = int256(target) - int256(current); // sell
        } else {
            deltaUSD = int256(target - current); // buy
        }
    }

    // Adds up the total USD value of the portfolio across all assets.
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

    // Figures out which assets have too much or too little capital in them.
    // Returns two lists: one for assets we need to sell from, and one to buy into.
    function computeRebalancePlan(
        string[] memory top10,
        mapping(string => uint256) storage weights,
        mapping(string => uint256) storage prices
    ) internal view returns (AssetAdjustment[] memory sells, AssetAdjustment[] memory buys) {
        uint256 totalValueUSD = getTotalPortfolioValue(top10, weights, prices);
        uint256 toleranceBps = 10; // allow a 0.1% deviation before acting

        AssetAdjustment[] memory overweights = new AssetAdjustment[](10);
        AssetAdjustment ;

        uint8 overIndex = 0;
        uint8 underIndex = 0;

        for (uint i = 0; i < top10.length; i++) {
            string memory asset = top10[i];
            uint256 price = prices[asset];
            uint256 target = (totalValueUSD * weights[asset]) / 10000;
            uint256 current = (price * weights[asset]) / 10000;

            if (current > target + (target * toleranceBps) / 10000) {
                overweights[overIndex++] = AssetAdjustment(asset, int256(current - target));
            } else if (current < target - (target * toleranceBps) / 10000) {
                underweights[underIndex++] = AssetAdjustment(asset, int256(target - current));
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

    // Adds up all the values in a list of adjustments.
    function sumAdjustments(AssetAdjustment[] memory adjustments) internal pure returns (uint256 total) {
        for (uint i = 0; i < adjustments.length; i++) {
            total += uint256(adjustments[i].deltaUSD);
        }
    }

    // Makes sure the amount we plan to buy equals what we plan to sell.
    // If not, we scale the buys to match the sells.
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
