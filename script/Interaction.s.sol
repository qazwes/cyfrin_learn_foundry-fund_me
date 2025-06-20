// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script,console} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {FundMe} from "../src/FundMe.sol";

// 与合约FundMe 的Fund函数进行交互的合约
contract Interaction_Fund_FundMe is Script {
    uint256 constant SEND_VALUE = 0.01 ether; 
    function FundMe_fund(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE}();
        vm.stopBroadcast();
        console.log("Funded FundMe contract with %s", SEND_VALUE);
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_fund(mostRecentlyDeployed);
    }
}
// 与合约FundMe 的withdraw函数进行交互的合约
contract Interaction_Withdraw_FundMe is Script {
    function FundMe_withdraw(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
    }

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("FundMe", block.chainid);
        FundMe_withdraw(mostRecentlyDeployed);
    }
}