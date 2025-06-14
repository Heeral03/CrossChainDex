// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {MockERC20} from "../src/MockERC20.sol";

contract CheckBalance is Script {
    function run() external {
        // Replace with your deployed MockERC20 addresses
        MockERC20 weth = MockERC20(0xAa49045062B3216CF5Cf41A36Ec17FdA7Ec61b34);
        MockERC20 usdc = MockERC20(0x5273cE0CFC959a12EDC5594eFD588034199D4f2D);

        // Replace with your wallet address (deployer or user)
        address user = 0x9468eAe58Af6431A5fBA10CA9A7313aac6afa23d;  // or hardcode your address here

        uint256 wethBalance = weth.balanceOf(user);
        uint256 usdcBalance = usdc.balanceOf(user);

        console.log("WETH Balance:", wethBalance);
        console.log("USDC Balance:", usdcBalance);
    }
}
