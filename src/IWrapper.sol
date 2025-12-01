// SPDX-License-Identifier: MIT
pragma solidity > 0.8.28;

/// @title Minimal interface for a token-to-USDC Wrapper
/// @notice Defines the core functionality for swapping any ERC20 token into USDC
/// @dev Implemented by the Wrapper contract, typically interacting with a DEX router

interface IWrapper {

    /// @notice Swaps a specified ERC20 token into USDC
    /// @param tokenIn The address of the ERC20 token to swap from
    /// @param amountIn The amount of tokenIn to swap
    /// @param amountOutMin The minimum acceptable amount of USDC to receive (slippage protection)
    /// @param recipient The address that will receive the resulting USDC
    /// @return amountOut The amount of USDC actually received by recipient
    function swapToUsdc(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) external returns (uint256 amountOut);


    /// @notice Estimates the amount of USDC that would be received for a given token input 
    /// @param tokenIn The address of the ERC20 token to swap from 
    /// @param amountIn The amount of `tokenIn` to swap 
    /// @return amountOut The estimated amount of USDC that would be received
    function previewSwapToUsdc(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
}
