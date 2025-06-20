//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    // 使用一个固定的虚拟地址来模拟测试中的发送交易(与合约交互)的账户
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; // 0.1 ETH
    uint256 constant STARTING_USER_BALANCE = 10 ether; // 10 ETH

    // 设置anvil链上的gas price
    uint256 constant GAS_PRICE = 1;
    
    function setUp() external{
        // 0x694AA1769357215DE4FAC081bf1f309aDC325306 Sepolia ETH/USD Address
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        
        // 先引入DeployFundMe.s.sol中的合约DeployFundMe
        DeployFundMe deployFundMe = new DeployFundMe();
        // 再调用run()方法来部署FundMe合约，这样做是为了只需要在DeployFundMe.s.sol修改就可以部署FundMe合约，而不需要每次还要修改测试合约FundMeTest.t.sol。
        fundMe = deployFundMe.run();

        // 设置账户USER的初始余额为10 ETH
        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testMinmumDollarIsFive() public view{ 
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18, "Minimum USD should be 5 Dollars");
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender, "Owner should be the message sender");
    }
    function testPriceFeedVersion() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4, "Price feed version should be 4");
    }
    function testFundFailsWithoutEnoughEth() public {
        // expectRevert是forge-std库中的一个函数，用于测试合约函数是否会触发revert。
        vm.expectRevert("You need to spend more ETH!");
        // 下面的代码是一个定义不会触发revert，那么测试就会失败
        // uint256 a = 1;

        // 下面的代码会触发revert 因为没有传入eth 但是函数fund要求传入的ETH小于5美元（5 * 10 ** 18 wei）
        // 如果没有触发revert，则测试会失败。
        fundMe.fund(); 
    }

    // 使用modifier 来简化 testOnlyOwnerCanWithdraw 中的测试代码
    // 如果需要多次发送ETH到FundMe合约，可以在modifier funded()中进行设置，这样就不需要在每个测试函数中重复写相同的代码。
    modifier funded() {
        vm.prank(USER); // 设置接下来所有的交易都由USER地址发送
        fundMe.fund{value: SEND_VALUE}(); // 发送1个ETH到FundMe合约
        _;
    }
    function testFundUpdatasFundedDataStructure() public funded {
        uint256 fundedAmount = fundMe.getAddressToAmountFunded(USER);
        assertEq(fundedAmount, SEND_VALUE, "Funded amount should be 1 ETH");
    }
    function testAddFunderToArray() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER, "Funder should be USER");
    }
    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER); // 设置接下来所有的交易都由USER地址发送
        // 现在USER尝试调用withdraw函数，应该会触发revert，因为withdraw函数只能由合约的所有者调用
        vm.expectRevert();
        fundMe.withdraw();
    }
    function testWithdrawWithASingleFunder() public funded {

        // Arrange 安排测试的前置条件
        // 在修饰符funded中已经发送了ETH到FundMe合约 startingContractBalance应该为SEND_VALUE
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // Act 执行测试的操作
        // gasleft() 函数返回当前剩余的gas 在发送合约之前是有设置最大gas limit的 而合约每笔交易都会消耗gas
        // uint256 gasStart = gasleft(); 
        // 设置交易的gas price
        // vm.txGasPrice(GAS_PRICE); 
        vm.prank(fundMe.getOwner()); // 设置接下来所有的交易都由 fundMe的所有者发送
        fundMe.withdraw();
        // uint256 gasUsed = gasStart - gasleft(); 
        // 计算消耗的gas 并在控制台打印
        // console.log(gasUsed * tx.gasprice);

        // Assert 验证测试的结果
        uint256 endingContractBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance; 
        assertEq(endingContractBalance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(endingOwnerBalance, startingOwnerBalance + startingContractBalance, "Owner balance should be increased by the contract balance after withdrawal");
    }
    function testWithdrawWithMultipleFunders() public funded {

        // Arrange 安排测试的前置条件
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // 从1开始，因为0已经是USER了 funded修饰符中USER已经发送了ETH到FundMe合约
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // 使用hoax来模拟多个不同的账户 每个账户有 SEND_VALUE 的ETH
            fundMe.fund{value: SEND_VALUE}(); // 然后发送ETH到FundMe合约
        }

        // Act 执行测试的操作
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        // 也可以使用类似startbroadcast 和 stopbroadcast的方式 来使用prank
        vm.startPrank(fundMe.getOwner()); // 设置接下来所有的交易都由 fundMe的所有者发送
        fundMe.withdraw();
        vm.stopPrank();

        // Assert 验证测试的结果
        assertEq( address(fundMe).balance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingContractBalance, "Owner balance should be increased by the contract balance after withdrawal");
    }
    function testCheaperWithdrawWithMultipleFunders() public funded {
        // Arrange 安排测试的前置条件
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; 
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); 
            fundMe.fund{value: SEND_VALUE}(); 
        }
        // Act 执行测试的操作
        uint256 startingContractBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        vm.startPrank(fundMe.getOwner()); 
        fundMe.CheaperWithdraw();
        vm.stopPrank();

        // Assert 验证测试的结果
        assertEq( address(fundMe).balance, 0, "Contract balance should be 0 after withdrawal");
        assertEq(fundMe.getOwner().balance, startingOwnerBalance + startingContractBalance, "Owner balance should be increased by the contract balance after withdrawal");
    }
}