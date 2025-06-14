// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../lib/forge-std/src/Script.sol";
import {IntentsManager} from "../../src/IntentsManager.sol";
import {CoWMatcher} from "../../src/CoWMatcher.sol";
import {CFMMAdapter} from "../../src/CFMMAdapter.sol";
import {SolverRouter} from "../../src/SolverRouter.sol";
import {CrossChainBridgeMock} from "../../src/CrossChainBridgeMock.sol";

contract DeployAll is Script {
    function run() external {
       uint256 deployerKey = uint256(vm.envBytes32("DEPLOYER_PRIVATE_KEY"));
        vm.startBroadcast(deployerKey);

        IntentsManager intents = new IntentsManager();
        console.log("IntentsManager:", address(intents));

        CoWMatcher cow = new CoWMatcher(address(intents));
        console.log("CoWMatcher:", address(cow));

        // Replace this with real router if needed
        address router = vm.envAddress("UNISWAP_ROUTER_ADDRESS");

        CFMMAdapter cfmm = new CFMMAdapter(router);
        console.log("CFMMAdapter:", address(cfmm));

        SolverRouter solverRouter = new SolverRouter(
            address(cow),
            address(cfmm),
            address(intents)
        );
        console.log("SolverRouter:", address(solverRouter));

        CrossChainBridgeMock bridge = new CrossChainBridgeMock();
        console.log("CrossChainBridgeMock:", address(bridge));

        vm.stopBroadcast();
    }
}
