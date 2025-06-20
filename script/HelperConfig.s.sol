//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
// 在本地测试链 anvil 上使用 mock 测试

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

// 这里继承Script主要就是为了实现 mock 虚拟合约的部署
contract HelperConfig is Script{

    struct NetworkConfig {
        // ETH/USD price feed address
        address priceFeed; 
    }
    NetworkConfig public activeNetworkConfig;
    
    uint8 public constant DECIMALS = 8; // 价格的精度
    int256 public constant INITIAL_ANSWER = 2000e8; // 初始价格为

    constructor () {
        if (block.chainid == 11155111) { // Sepolia
            activeNetworkConfig = getSepoliaETHConfig();
        } else if (block.chainid == 31337) { // Anvil
            activeNetworkConfig = getAnvilConfig();
        } else if (block.chainid == 1) { // Mainnet
            activeNetworkConfig = getMainnetETHConfig();
        } 
        else {
            revert("Unsupported network");
        }
    }

    function getSepoliaETHConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
       NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        }); 
        return sepoliaConfig;// Sepolia ETH/USD Address
    } 

    function getMainnetETHConfig()
        public
        pure
        returns (NetworkConfig memory)
    {
       NetworkConfig memory mainnetConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        }); 
        return mainnetConfig;// Sepolia ETH/USD Address
    } 


    function getAnvilConfig()
        public
        returns (NetworkConfig memory)
    {
        if(activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig; // 如果已经有配置了，就直接返回
        }

        // 在 mainnet 和 sepolia 上都是存在对应的合约的 0x694AA1769357215DE4FAC081bf1f309aDC325306 和 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // 但是在 anvil 上没有对应的ETH/USD合约，所以我们需要使用 mock 合约来模拟
        vm.startBroadcast();
        // 我们手动设置ETH的价格为2000美元，8位小数
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(DECIMALS, INITIAL_ANSWER); // 2000 USD in 8 decimal places
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockV3Aggregator) // 返回 mock 合约的地址
        });
        return anvilConfig; // Anvil ETH/USD Address
    }
}