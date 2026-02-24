// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/BatchSender.sol";

contract DeployAndSend is Script {
    function run() external {
        vm.startBroadcast();
        
        // Deploy the BatchSender contract
        BatchSender sender = new BatchSender();
        console.log("BatchSender deployed at:", address(sender));
        
        vm.stopBroadcast();
    }
}
