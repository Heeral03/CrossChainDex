// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { CCIPSender } from "../src/ccip/CCIPSender.sol";

contract SendIntent is Script {
    function run() external {
        vm.startBroadcast();

        // Address of the deployed CCIPSender
        CCIPSender sender = CCIPSender(payable(0xYour_Sender_Address));

        string memory message = "SwapIntent:ETH→MATIC";
        uint64 destinationChainSelector = 16281711391670634445; // Amoy selector

        // Send message with 0.01 ETH for CCIP fees
        sender.sendIntent{value: 0.01 ether}(message, destinationChainSelector);

        vm.stopBroadcast();
    }
}