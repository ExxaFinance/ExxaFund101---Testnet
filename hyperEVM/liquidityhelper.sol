// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library LiquidityHelper {
    using SafeERC20 for IERC20;

    /**
     * @notice Adds liquidity for a token/token pair
     * @dev Requires router approval and token transfers before calling
     * @param router Address of UniswapV2Router02-compatible DEX
     * @param tokenA Address of first token
     * @param tokenB Address of second token
     * @param amountADesired Amount of tokenA to add
     * @param amountBDesired Amount of tokenB to add
     * @param amountAMin Minimum tokenA accepted (slippage)
     * @param amountBMin Minimum tokenB accepted (slippage)
     * @param to LP tokens receiver
     * @param deadline Tx deadline
     */
    function addLiquidity(
        address router,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        // Approve and transfer tokens
        IERC20(tokenA).safeIncreaseAllowance(router, amountADesired);
        IERC20(tokenB).safeIncreaseAllowance(router, amountBDesired);

        // Add liquidity
        (amountA, amountB, liquidity) = IUniswapV2Router02(router).addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    /**
     * @notice Adds liquidity for a token/ETH pair
     * @dev Token must be pre-approved and transferred
     * @param router Address of UniswapV2Router02-compatible DEX
     * @param token ERC20 token address
     * @param amountTokenDesired Token amount
     * @param amountTokenMin Min token allowed
     * @param amountETHMin Min ETH allowed
     * @param to Receiver of LP tokens
     * @param deadline Deadline for tx
     */
    function addLiquidityETH(
        address router,
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) internal returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        // Approve tokens
        IERC20(token).safeIncreaseAllowance(router, amountTokenDesired);

        // Add liquidity with ETH
        (amountToken, amountETH, liquidity) = IUniswapV2Router02(router).addLiquidityETH{value: amountETHMin}(
            token,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
    }
}

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
