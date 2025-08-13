-include .env

# PRE-DEPLOYMENT CHECKS...
#
# You need to activate your address/account on HyperCore
# - do this by logging into HyperCore testnet
# - and getting 1000 USDC from the faucet: https://app.hyperliquid-testnet.xyz/drip
#
# Get some HYPE for gas on HyperEVM: https://www.gas.zip/faucet/hyperevm
#
# Switch your deployer account to 'Big Blocks': https://hyperevm-block-toggle.vercel.app/
# - if you haven't activated your address/account switching to Big Blocks will fail
#
# ...you should be ready to deploy now :-)

# 1) Deploy the HyperVault Contract to HyperEVM
deploy-hypervault-contract:
	forge script script/DeployHyperVault.s.sol:DeployHyperVault --broadcast --legacy --account deployer -vvvvv

# 2) Check the totalAssets in the HyperVault (should be 0 initially)
get-total-assets:
	cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_MAINNET_RPC)

# 3) Using the Mainnet GUI: https://app.hyperliquid.xyz/portfolio
# 3.1) Transfer some USDC from HyperCore Perps => HyperCore Spot
# 3.2) Then transfer the USDC from HyperCore Spot => HyperEVM
# 3.3) You should now get your USDC balance on HyperEVM using this call...
get-my-usdt-balance:
	cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_MAINNET_RPC)

# 4) Transfer 1e4 (i.e. $0.01 USDC) to your HyperVault
transfer-to-contract:
	cast send $(USDT_MAINNET) "transfer(address,uint256)" $(HYPERVAULT) 1e4 --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# Now Check the HyperVault balance above again! (totalAssets should be == $1 USDC now)

# 5) Approve + Deposit some USDT into the HyperVault
approve-usdt-to-hypervault:
	cast send $(USDT_MAINNET) "approve(address,uint256)(bool)" $(HYPERVAULT) 1e18 --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

deposit-usdt-to-hypervault:
	cast send $(HYPERVAULT) "deposit(uint256,address)(bool)" 1e6 $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# 6) Withdraw from Hypervault on HyperCore
withdraw-usdt-from-hypervault-on-core:
	cast send $(HYPERVAULT) "withdraw(uint256,address,address)(uint256)" 1e4 $(DEPLOYER_PUBLIC_ADDRESS) $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)


# Set Token Info - TESTNET
set-token-info: # PURR token
	cast send $(TOKEN_REGISTRY_TESTNET) "setTokenInfo(uint32)" 0  --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# Get Token Index - TESTNET
get-token-index-via-hypervault:
	cast call $(HYPERVAULT) "getTokenIndex(address)(uint64)" $(USDC_HYPEREVM) --rpc-url $(HYPEREVM_TESTNET_RPC)

get-token-index-via-registry:
	cast call $(TOKEN_REGISTRY_TESTNET) "getTokenIndex(address)(uint32)" $(USDC_HYPEREVM) --rpc-url $(HYPEREVM_TESTNET_RPC)

get-purr-index:
	cast call $(HYPERVAULT) "getTokenIndex(address)(uint64)" 0xa9056c15938f9aff34cd497c722ce33db0c2fd57 --rpc-url $(HYPEREVM_TESTNET_RPC)

# Get Token Index - MAINNET - WORKING FINE
get-token-index-mainnet:
	cast call $(TOKEN_REGISTRY_MAINNET) "getTokenIndex(address)(uint32)" $(USDT_MAINNET) --rpc-url $(HYPEREVM_MAINNET_RPC)

get-hypervault-usdt-balance:
	cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(HYPERVAULT) --rpc-url $(HYPEREVM_MAINNET_RPC)

# Deploy Token Registry to HyperEVM Testnet
deploy-token-registry-contract:
	forge script script/DeployTokenRegistry.s.sol:DeployTokenRegistry --broadcast --legacy --account deployer -vvvvv

# cURL to get HyperVault balance on Core
curl-get-hypervault-balance-on-core:
	curl -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "0x7490fc19fdf1063ECb07d1980D1a960b9b57b63a"}'
