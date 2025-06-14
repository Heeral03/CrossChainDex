// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import "../src/MockERC20.sol";

contract DeployMocks is Script {
    function run() external {
        vm.startBroadcast();

        // Deploy Mock WETH and USDC
        MockERC20 weth = new MockERC20("Wrapped Ether", "WETH");
        MockERC20 usdc = new MockERC20("USD Coin", "USDC");

        // Replace this with the actual user address (the one you use in your tests/scripts)
        address user = vm.addr(0xf130e80c73d5f39a25df5934aed4d5ea49f8fcd358746515442c5ab6b095597e);


        // Mint 100 tokens (1e20 wei) to the user address
        uint256 mintAmount = 100 ether;
        weth.mint(user, mintAmount);
        usdc.mint(user, mintAmount);

        vm.stopBroadcast();

        console.log("Mock WETH deployed at:", address(weth));
        console.log("Mock USDC deployed at:", address(usdc));
        console.log("Minted 100 WETH and 100 USDC to user:", user);
    }
}
