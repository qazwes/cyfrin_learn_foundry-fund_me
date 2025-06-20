//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Interaction_Fund_FundMe} from "../../script/Interaction.s.sol";
import {Interaction_Withdraw_FundMe} from "../../script/Interaction.s.sol";

contract InteractionTest is Test {
    FundMe fundMe;

    // 使用一个固定的虚拟地址来模拟测试中的发送交易(与合约交互)的账户
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 0.1 ETH
    uint256 constant STARTING_USER_BALANCE = 10 ether; // 10 ETH

    // 设置anvil链上的gas price
    uint256 constant GAS_PRICE = 1;
    
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_USER_BALANCE);
    }
    function testUserCanFundInteraction() public {
        Interaction_Fund_FundMe fund_FundMe = new Interaction_Fund_FundMe();
        fund_FundMe.FundMe_fund(address(fundMe));

        Interaction_Withdraw_FundMe withdraw_FundMe = new Interaction_Withdraw_FundMe();
        withdraw_FundMe.FundMe_withdraw(address(fundMe));

        assertEq(address(fundMe).balance, 0, "FundMe contract balance should be 0 after withdrawal");   
    }
}