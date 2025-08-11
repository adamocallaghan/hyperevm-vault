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
	cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)

# 3) Using the Testnet GUI: https://app.hyperliquid-testnet.xyz/portfolio
# 3.1) Transfer some USDC from HyperCore Perps => HyperCore Spot
# 3.2) Then transfer the USDC from HyperCore Spot => HyperEVM
# 3.3) You should now get your USDC balance on HyperEVM using this call...
get-my-usdc-balance:
	cast call $(USDC_HYPEREVM) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_TESTNET_RPC)

# 4) Transfer 1e8 (i.e. $1 USDC) to your HyperVault
transfer-to-contract:
	cast send $(USDC_HYPEREVM) "transfer(address,uint256)" $(HYPERVAULT) 1e8 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# Now Check the HyperVault balance above again! (totalAssets should be == $1 USDC now)

# 5) Approve + Deposit some USDC into the HyperVault
approve-usdc-to-hypervault:
	cast send $(USDC_HYPEREVM) "approve(address,uint256)(bool)" $(HYPERVAULT) 1e18 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

deposit-usdc-to-hypervault:
	cast send $(HYPERVAULT) "deposit(uint256,address)(bool)" 1e8 $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)




# Deploy Token Registry to HyperEVM Testnet
deploy-token-registry-contract:
	forge script script/DeployTokenRegistry.s.sol:DeployTokenRegistry --broadcast --legacy --account deployer -vvvvv