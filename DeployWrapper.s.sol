// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {Wrapper} from "../src/Wrapper.sol";

contract DeployWrapper is Script {
    function run() external returns (Wrapper wrapper) {
        // Direcciones del video (BSC Testnet)
        address _router = address(0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe);
        address _usdc   = address(0x55d398326f99059fF775485246999027B3197955); // USDC (base stable)

        vm.startBroadcast();
        wrapper = new Wrapper(_router, _usdc);
        vm.stopBroadcast();
    }
}
