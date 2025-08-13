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
	cast send $(HYPERVAULT) "deposit(uint256,address)(bool)" 1e4 $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# 6) Withdraw from Hypervault on HyperCore
withdraw-usdt-from-hypervault-on-core:
	cast send $(HYPERVAULT) "withdraw(uint256,address,address)(uint256)" 1e4 $(DEPLOYER_PUBLIC_ADDRESS) $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# Get Token Index - MAINNET - WORKING FINE
get-token-index-mainnet:
	cast call $(TOKEN_REGISTRY_MAINNET) "getTokenIndex(address)(uint32)" $(USDT_MAINNET) --rpc-url $(HYPEREVM_MAINNET_RPC)

get-hypervault-usdt-balance:
	cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(HYPERVAULT) --rpc-url $(HYPEREVM_MAINNET_RPC)

# cURL to get HyperVault balance on Core
curl-get-hypervault-balance-on-core:
	curl -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(HYPERVAULT)"}'

curl-get-user-balance-on-core:
	curl -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(DEPLOYER_PUBLIC_ADDRESS)"}'


# GET ALL BALANCES
get-all-balances:
	@echo "Fetching HyperEVM Balances..."
	@total_assets=$$(cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_MAINNET_RPC)); \
	my_usdt=$$(cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_MAINNET_RPC)); \
	hypervault_usdt=$$(cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(HYPERVAULT) --rpc-url $(HYPEREVM_MAINNET_RPC)); \
	echo "On-chain Total Assets: $$total_assets"; \
	echo "My USDT Balance: $$my_usdt"; \
	echo "HyperVault USDT Balance: $$hypervault_usdt"; \
	\
	echo ""; \
	echo "Fetching HyperVault balances from HyperLiquid Core..."; \
	hv_core=$$(curl -s -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(HYPERVAULT)"}'); \
	echo "$$hv_core" | jq -r '.balances[] | "\(.coin): \(.total)"'; \
	\
	echo ""; \
	echo "Fetching Your User/Deployer balances from HyperLiquid Core..."; \
	user_core=$$(curl -s -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(DEPLOYER_PUBLIC_ADDRESS)"}'); \
	echo "$$user_core" | jq -r '.balances[] | "\(.coin): \(.total)"'
