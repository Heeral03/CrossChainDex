// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { CCIPSender } from "../src/ccip/CCIPSender.sol";

contract DeploySender is Script {
    function run() external {
        vm.startBroadcast();

        // Sepolia CCIP router
        address router = 0xD0daae2231E9CB96b94C8512223533293C3693Bf;

        // Replace this with your deployed receiver on Amoy
        address receiver = 0x10c2F8062836413743C5BAbe59C05f404e5fE072;

        CCIPSender sender = new CCIPSender(router, receiver);

        console.log("CCIPSender deployed to:", address(sender));
        vm.stopBroadcast();
    }
}