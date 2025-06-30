# 如果使用make命令 Makefile是默认的目标文件名 使用MakeFile会报错   
-include .env

build:; forge build

deploy_sepolia:
	forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $(SEPOLIA_RPC_URL) 
	--private-key $(PRIVATE_KEY) --broadcast --verify 
	--etherscan-api-key $(ETHERSCAN_API_KEY) -vvvv

deploy_anvil:
	@forge script script/DeployFundMe.s.sol:DeployFundMe $(NETWORK_ARGS)
NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

