// SPDX-License-Identifier: MIT
pragma solidity > 0.8.28;

/// @notice Minimal interface for the Wrapper contract used to swap tokens -> USDC.
interface IWrapper {
    function swapToUsdc(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256 amountOut);

    function previewSwapToUsdc(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
}