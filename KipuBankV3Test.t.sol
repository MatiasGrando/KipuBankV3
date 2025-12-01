// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "../src/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockPriceFeed is AggregatorV3Interface {
    function decimals() external pure override returns (uint8) { return 6; }
    function description() external pure override returns (string memory) { return "Mock"; }
    function version() external pure override returns (uint256) { return 1; }
    function getRoundData(uint80) external pure override returns (uint80, int256, uint256, uint256, uint80) { 
        return (0, 1e6, 0, 0, 0); 
    }
    function latestRoundData() external pure override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, 1e6, 0, 0, 0); // precio de 1 USDC = 1 USDC
    }
}

// -----------------------------
// Mock ERC20 para pruebas
// -----------------------------
contract MockERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// -----------------------------
// Mock Wrapper para pruebas
// -----------------------------
contract MockWrapper is IWrapper {
    function swapToUsdc(address, uint256 amount, uint256, address) external pure override returns (uint256) {
        return amount/1e12; // retorna el mismo monto para pruebas
    }

    function previewSwapToUsdc(address, uint256 amount) external pure override returns (uint256) {
        return amount/1e12; // retorna el mismo monto para pruebas
    }
}

// -----------------------------
// Test del KipuBankV3
// -----------------------------
contract KipuBankV3Test is Test {
    KipuBankV3 public bank;
    MockERC20 public usdc;
    MockERC20 public tokenA;
    MockWrapper public mockWrapper;

    address constant USER = address(0x1234);
    address constant OWNER = address(0xABCD);

    function setUp() public {
// -----------------------------
// Definir mocks
// -----------------------------
usdc = new MockERC20("USD Coin", "USDC");
tokenA = new MockERC20("Token A", "TKA");
mockWrapper = new MockWrapper();
MockPriceFeed mockUSDCFeed = new MockPriceFeed();
MockPriceFeed mockTokenAFeed = new MockPriceFeed(); // para cualquier token adicional
MockPriceFeed mockETHFeed = new MockPriceFeed(); // mock ETH/USD feed para evitar revert

// -----------------------------
// Mint tokens a USER
// -----------------------------
usdc.mint(USER, 1_000_000e6);
tokenA.mint(USER, 1_000_000e18);

// -----------------------------
// Deploy KipuBankV3
// -----------------------------
bank = new KipuBankV3(
    1000e6,             // max withdraw por tx
    100_000e6,          // max bank cap
    address(usdc),      // token principal
    OWNER,              // owner
    address(mockWrapper) // wrapper
);

// -----------------------------
// Setear PriceFeeds como owner
// -----------------------------
vm.prank(OWNER);
bank.setPriceFeed(address(usdc), address(mockUSDCFeed));

vm.prank(OWNER);
bank.setPriceFeed(address(tokenA), address(mockTokenAFeed));

vm.prank(OWNER);
bank.setPriceFeed(address(0), address(mockETHFeed)); // mock ETH/USD

// -----------------------------
// Revisar que los feeds se setearon correctamente (opcional)
// -----------------------------
console.log("USDC Feed:", address(bank.priceFeeds(address(usdc))));
console.log("TokenA Feed:", address(bank.priceFeeds(address(tokenA))));
console.log("ETH Feed:", address(bank.priceFeeds(address(0))));

}


    // -----------------------------
    // Test deposit USDC
    // -----------------------------
    function testDepositUSDC() public {
        vm.startPrank(USER);
        usdc.approve(address(bank), type(uint256).max);

        bank.depositToken(1000e6, address(usdc), 6);

        uint256 balance = bank.userTokenBalance(USER, address(usdc));
        assertEq(balance, 1000e6, "USDC deposit failed");

        vm.stopPrank();
    }

    // -----------------------------
    // Test deposit TokenA and convert to USDC via wrapper
    // -----------------------------
    function testDepositTokenAndConvert() public {
        vm.startPrank(USER);
        tokenA.approve(address(bank), type(uint256).max);

        bank.depositTokenAndConvert(address(tokenA), 500e18, 0);

        uint256 balanceUSDC = bank.userTokenBalance(USER, address(usdc));
        assertEq(balanceUSDC, 500e6, "Conversion to USDC failed");

        vm.stopPrank();
    }

    // -----------------------------
    // Test withdraw USDC
    // -----------------------------
    function testWithdrawUSDC() public {
        vm.startPrank(USER);
        usdc.approve(address(bank), type(uint256).max);
        bank.depositToken(1000e6, address(usdc), 6);

        bank.withdrafToken(500e6, address(usdc), 6);

        uint256 balance = bank.userTokenBalance(USER, address(usdc));
        assertEq(balance, 500e6, "USDC withdraw failed");

        vm.stopPrank();
    }
}

