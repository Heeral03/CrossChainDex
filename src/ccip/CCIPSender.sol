// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "../../lib/chainlink-brownie-contracts/contracts/src/v0.8/ccip/libraries/Client.sol";
import {IERC20} from "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract CCIPSender {
    address public router;
    address public receiver;

    event TokensSent(
        bytes32 messageId,
        uint64 destinationChainSelector,
        address receiver,
        address token,
        uint256 amount,
        string message
    );

    constructor(address _router, address _receiver) {
        router = _router;
        receiver = _receiver;
    }

    function sendTokensWithMessage(
        address tokenAddress,
        uint256 tokenAmount,
        string memory message,
        uint64 destinationChainSelector
    ) external payable {
        // Transfer tokens
        require(
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount),
            "Token transfer failed"
        );
        
        // Approve router
        require(
            IERC20(tokenAddress).approve(router, tokenAmount),
            "Approval failed"
        );

        // Create tokenAmounts array
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = Client.EVMTokenAmount({
            token: tokenAddress,
            amount: tokenAmount
        });

        // ⚠ Fix: Struct initialization must use positional arguments
         Client.EVMExtraArgsV1 memory extraArgsV1 = Client.EVMExtraArgsV1(200000);
        bytes memory extraArgs = abi.encode(extraArgsV1);

        // Construct message
        Client.EVM2AnyMessage memory ccipMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: bytes(message),
            tokenAmounts: tokenAmounts,
            feeToken: address(0),
            extraArgs: extraArgs
        });

        // Send message
        bytes32 messageId = IRouterClient(router).ccipSend{value: msg.value}(
            destinationChainSelector,
            ccipMessage
        );

        emit TokensSent(
            messageId,
            destinationChainSelector,
            receiver,
            tokenAddress,
            tokenAmount,
            message
        );
    }

    receive() external payable {}
}