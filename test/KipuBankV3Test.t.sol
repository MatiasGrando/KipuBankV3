// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Tests for the KipuBankV3 contract
/// @author Matias Grando
/// @notice This contract contains unit tests for the KipuBankV3 functionality
/// @dev Uses Foundry's forge-std/Test.sol for testing ERC20 deposits, withdrawals, and token-to-USDC conversion


import "forge-std/Test.sol";
import "../src/KipuBankV3.sol";
import "../src/IWrapper.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


/// @notice Provides mock implementations of ERC20 tokens, price feeds, and a wrapper for testing purposes
/// @dev These contracts are only intended for local or forked test environments
/// @notice Mock Chainlink price feed implementing AggregatorV3Interface
contract MockPriceFeed is AggregatorV3Interface {
    /// @notice Returns the number of decimals for the price feed
    function decimals() external pure override returns (uint8) { return 6; }

    /// @notice Returns a description for the price feed
    function description() external pure override returns (string memory) { return "Mock"; }

    /// @notice Returns the version of the feed interface
    function version() external pure override returns (uint256) { return 1; }

    /// @notice Returns historical round data (mocked) 
    /// @param _ ignored, as this is a mock 
    /// @return roundId, answer, startedAt, updatedAt, answeredInRound
    function getRoundData(uint80) external pure override returns (uint80, int256, uint256, uint256, uint80) { 
        return (0, 1e6, 0, 0, 0); 
    }

    /// @notice Returns the latest round data (mocked) 
    /// @return roundId, answer, startedAt, updatedAt, answeredInRound
    function latestRoundData() external pure override returns (uint80, int256, uint256, uint256, uint80) {
        return (0, 1e6, 0, 0, 0); // precio de 1 USDC = 1 USDC
    }
}

// -----------------------------
// Mock ERC20 para pruebas
// -----------------------------
/// @notice Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /// @notice Mints tokens to a specified address 
    /// @param to Recipient address 
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

// -----------------------------
// Mock Wrapper para pruebas
// -----------------------------
/// @notice Mock Wrapper contract for testing token-to-USDC swaps
contract MockWrapper is IWrapper {

    /// @notice Swaps tokens to USDC (mock implementation)
    /// @param _ ignored
    /// @param amount Amount of input tokens
    /// @param _ ignored
    /// @param _ ignored
    /// @return The resulting amount of USDC
    function swapToUsdc(address, uint256 amount, uint256, address) external pure override returns (uint256) {
        return amount/1e12; // retorna el mismo monto para pruebas
    }

    /// @notice Previews the USDC amount that would be received for a swap (mock implementation) 
    /// @param _ ignored 
    /// @param amount Amount of input tokens 
    /// @return The resulting amount of USDC
    function previewSwapToUsdc(address, uint256 amount) external pure override returns (uint256) {
        return amount/1e12; // retorna el mismo monto para pruebas
    }
}

// -----------------------------
// Test del KipuBankV3
// -----------------------------
contract KipuBankV3Test is Test {
    /// @notice Instance of the bank contract under test
    KipuBankV3 public bank;
    /// @notice Mock USDC ERC20 token used for testing
    MockERC20 public usdc;
    /// @notice Mock ERC20 token used for testing swaps
    MockERC20 public tokenA;
    /// @notice Mock wrapper contract for token-to-USDC conversion
    MockWrapper public mockWrapper;
    /// @notice Predefined test user address
    address constant USER = address(0x1234);
    /// @notice Predefined test owner address
    address constant OWNER = address(0xABCD);

    /// @notice Setup function called before each test 
    /// @dev Deploys mocks, mints tokens, deploys the bank, and sets price feeds
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
    // Revisar que los feeds se setearon correctamente 
    // -----------------------------
    console.log("USDC Feed:", address(bank.priceFeeds(address(usdc))));
    console.log("TokenA Feed:", address(bank.priceFeeds(address(tokenA))));
    console.log("ETH Feed:", address(bank.priceFeeds(address(0))));

    }


    // -----------------------------
    // Test deposit USDC
    // -----------------------------
    /// @notice Tests depositing USDC tokens into the bank 
    /// @dev Approves the bank to spend USDC, deposits 1000 USDC, and asserts internal balance
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
    /// @notice Tests depositing a token and converting it to USDC via the wrapper 
    /// @dev Approves the bank to spend tokenA, deposits 500 tokenA, converts to USDC, and asserts resulting USDC balance
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
    /// @notice Tests withdrawing USDC from the bank 
    /// @dev Deposits 1000 USDC first, then withdraws 500 USDC, and asserts the remaining balance
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

