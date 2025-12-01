// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/// @title Tests for the Wrapper contract
/// @author Matias Grando
/// @notice This contract contains unit tests for the Wrapper functionality on ZetaChain
/// @dev Uses Foundry's forge-std/Test.sol to test token swaps via the Wrapper
//import {Test} from "forge-std/Test.sol";

import "forge-std/Test.sol";
import {Wrapper} from "../src/Wrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract WrapperTest is Test {

    /// @notice Instance of the Wrapper contract under test
    Wrapper public wrapper;

    /// @notice Router address used by the Wrapper for swaps
    address constant ROUTER = 0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe;

    /// @notice USDC token address
    address constant USDC = 0xfC9201f4116aE6b054722E10b98D904829b469c3;

    /// @notice WETH token address (if needed for swaps)
    address constant WETH = 0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91;

    /// @notice Whale account holding large token balances for testing
    address constant WHALE = 0xc534f1528FA2bA9f72c7fC6F5A21450DbB3C08d2;

    /// @notice Regular user account to receive swap outputs
    address constant USER = 0xa0Ee7A142d267C1f36714E4a8F75612F20a79720;

    /// @notice Setup function called before each test 
    /// @dev Creates a fork of ZetaChain mainnet and deploys the Wrapper contract
    function setUp() public {
        vm.createSelectFork("https://zetachain-evm.blockpi.network/v1/rpc/public");
        wrapper = new Wrapper(ROUTER,USDC);
    }

    /// @notice Tests swapping USDC to USDC via the Wrapper 
    /// @dev Starts a prank as the WHALE, approves the wrapper, performs the swap, and asserts that the USER balance increased
    function testSwapUSDCtoUSDC() public {
        vm.startPrank(WHALE);
        uint256 amountIn = 1_000_000; // 1 USDC (6 decimals)
        uint256 before = IERC20(USDC).balanceOf(USER);

        console.log("Balance before swap:", before);

        IERC20(USDC).approve(address(wrapper), type(uint256).max);
        wrapper.swapToUsdc(USDC, amountIn, 0, USER);

        uint256 afterBal = IERC20(USDC).balanceOf(USER);

        console.log("Balance after swap:", afterBal);

        assertGt(afterBal, before, "swap failed");
        vm.stopPrank();
    }

    /// @notice Tests that swapping USDC without approval reverts 
    /// @dev Starts a prank as the WHALE, calls swap without approval, and expects a revert
    function testSwapUSDCtoUSDCMustRevert() public {
        vm.startPrank(WHALE);
        uint256 amountIn = 1_000_000; // 1 USDC (6 decimals)
        uint256 before = IERC20(USDC).balanceOf(USER);

        console.log("Balance before swap:", before);
        
        vm.expectRevert();

        //IERC20(USDC).approve(address(wrapper), type(uint256).max);
        wrapper.swapToUsdc(USDC, amountIn, 0, USER);

        
        uint256 afterBal = IERC20(USDC).balanceOf(USER);

        console.log("Balance after swap:", afterBal);

        //assertGt(afterBal, before, "swap failed");
        vm.stopPrank();
    }
    
}
