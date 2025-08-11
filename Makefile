-include .env

# Deploy HyperVault Contract to HyperEVM
deploy-hypervault-contract:
	forge script script/DeployHyperVault.s.sol:DeployHyperVault --broadcast --legacy --account deployer -vvvvv

# Checking your HyperVault (should be 0 initially)
get-total-assets:
	cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)

# Transfer some USDC from HyperCore Perps => HyperCore Spot, then to HyperEVM
# You should now get your balance using this call
get-my-usdc-balance:
	cast call $(USDC_HYPEREVM) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_TESTNET_RPC)

# Transfer 1e8 (i.e. $1 USDC) to the HyperVault
transfer-to-contract:
	cast send $(USDC_HYPEREVM) "transfer(address,uint256)" $(HYPERVAULT) 1e8 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# Now Check the HyperVault balance above again! (totalAssets should be == $1 USDC now)
