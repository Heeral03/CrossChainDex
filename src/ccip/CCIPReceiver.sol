// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { CCIPReceiver } from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";

contract CCIPReceiverExample is CCIPReceiver {
    event MessageReceived(string message, address sender, uint64 sourceChainSelector);

    constructor(address router) CCIPReceiver(router) {}

    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        string memory decodedMessage = abi.decode(message.data, (string));

        emit MessageReceived(
            decodedMessage,
            abi.decode(message.sender, (address)),
            message.sourceChainSelector
        );

        // Optional: add business logic here
    }
}