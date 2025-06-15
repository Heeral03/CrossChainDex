// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { CCIPReceiverExample } from "../src/ccip/CCIPReceiver.sol";

contract DeployReceiver is Script {
    function run() external {
        vm.startBroadcast();

        address router = 0xE561D5E02207FEd60EAFCeeFdCEEF1FCBd0D645e;

        address solverRouter = 0xf123E97F72168B93767EECd68bf289A11AC2A0B9;

        CCIPReceiverExample receiver = new CCIPReceiverExample(router);

        console.log("Receiver deployed to:", address(receiver));

        vm.stopBroadcast();
    }
}
