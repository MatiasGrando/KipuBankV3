// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {IWrapper} from "./IWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

/// @title Token Wrapper to USDC via UniswapV2
/// @author Matias Grando
/// @notice This contract allows swapping any ERC20 token to USDC using UniswapV2
/// @dev Implements the IWrapper interface and uses SafeERC20 for secure token transfers
contract Wrapper is IWrapper{
    using SafeERC20 for IERC20;

    /// @notice Error thrown when a zero address is passed
    error ZeroAddress();
    /// @notice Error thrown when a zero amount is passed
    error ZeroAmount();

    /// @notice UniswapV2 router address used for swaps
    IUniswapV2Router02 public immutable ROUTER;
    /// @notice USDC token address
    address public immutable USDC;
    /// @notice WETH token address from the router
    address public immutable WETH;

    /// @param _router Address of the UniswapV2 router 
    /// @param _usdc Address of the USDC token
    constructor(address _router, address _usdc) {
        if (_router == address(0) || _usdc == address(0)) revert ZeroAddress();
        ROUTER = IUniswapV2Router02(_router);
        USDC = _usdc;
        WETH = ROUTER.WETH();
    }

    /// @notice Swap any ERC20 token to USDC 
    /// @param tokenIn Address of the token to swap 
    /// @param amountIn Amount of tokens to swap 
    /// @param amountOutMin Minimum amount of USDC expected to receive 
    /// @param recipient Address that will receive the USDC 
    /// @return amountOut Amount of USDC actually received 
    /// @dev If tokenIn is already USDC, it is transferred directly to the recipient 
    /// @dev Ensures approval for the router if needed
    function swapToUsdc(address tokenIn, uint256 amountIn, uint256 amountOutMin, address recipient)
        external
        returns (uint256 amountOut)
    {
        
        if (tokenIn == address(0) || recipient == address(0)) revert ZeroAddress();
        if (amountIn == 0) revert ZeroAmount();

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        if (tokenIn == USDC) {
            IERC20(USDC).safeTransfer(recipient, amountIn);
            return amountIn;
        }

        // ensure allowance for router
        if (IERC20(tokenIn).allowance(address(this), address(ROUTER)) < amountIn) {
            //IERC20(tokenIn).safeApprove(address(router), 0);
            IERC20(tokenIn).safeIncreaseAllowance(address(ROUTER), type(uint256).max);
        }

        address[] memory path;
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = USDC;
        

        uint256[] memory amounts =
            ROUTER.swapExactTokensForTokens(amountIn, amountOutMin, path, recipient, block.timestamp);

        amountOut = amounts[amounts.length - 1];
    }

    /// @notice Simulate a token swap to USDC without executing it 
    /// @param tokenIn Address of the token to simulate the swap 
    /// @param amountIn Amount of tokens to simulate 
    /// @return amountOut Amount of USDC that would be received 
    /// @dev If tokenIn is USDC, returns amountIn directly
    function previewSwapToUsdc(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        if (tokenIn == address(0)) revert ZeroAddress();
        if (amountIn == 0) revert ZeroAmount();

        if (tokenIn == USDC) {
            return amountIn;
        }

        address[] memory path;
            path = new address[](2);
            path[0] = tokenIn;
            path[1] = USDC;
        
        uint256[] memory amounts = ROUTER.getAmountsOut(amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }
}
