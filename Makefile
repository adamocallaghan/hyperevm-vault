-include .env

# PRE-DEPLOYMENT CHECKS...
#
# You need to activate your address/account on HyperCore
#
# MAINNET:
# - you'll need some USDC in your HyperCore account (account activation)
# - you'll need some HYPE in your HyperEVM account (for gas)
# 
# TESTNET: 
# - log into HyperCore testnet: https://app.hyperliquid-testnet.xyz
# - and getting 1000 USDC from the faucet: https://app.hyperliquid-testnet.xyz/drip
# - get some HYPE for gas on HyperEVM: https://www.gas.zip/faucet/hyperevm
#
# BIG BLOCKS:
# - switch your deployer account to 'Big Blocks': https://hyperevm-block-toggle.vercel.app/
# - if you haven't activated your address/account switching to Big Blocks will fail
#
# ...you should be ready to deploy now :-)

# 1) Deploy the HyperVault Contract to HyperEVM
deploy-hypervault-contract:
	NETWORK=testnet forge script script/DeployHyperVault.s.sol:DeployHyperVault --broadcast --legacy --account deployer -vvvvv

# POST-DEPLOYMENT NOTE: make sure to transfer $1 USDC Spot from your own account to the Hypervault address on HyperCore, this will activate the Hypervault *Contract Address* on HyperCore so you can use CoreWriter

# .ENV FILE: Add your deployed HyperVault address as "HYPERVAULT=0x123..." so the rest of these commands work

# 2) Check the totalAssets in the HyperVault (should be 0 initially)
get-total-assets:
	cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_MAINNET_RPC)

# USDT vs USDC: there is no linked USDC on HyperEVM Mainnet yet, only on Testnet
# I started developing this project on Testnet with USDC, but switched to Mainnet with USDT
# This was because I had some issues with tokenIds and the TokenRegistry, and it was just easier
# and cleaner to use Mainnet,  where everything is working spot on, and spend a few USDT instead.
# Once everything is working I will loop back around and get it set up for using USDC on Testnet.

# 3) Using the Mainnet GUI: https://app.hyperliquid.xyz/portfolio
# 3.1) Transfer some USDC from HyperCore Perps => HyperCore Spot
# 3.2) Swap your USDC to USDT
# 3.3) Transfer the USDT from HyperCore Spot => HyperEVM
# 3.4) You should now get your USDT balance on HyperEVM using this call...
get-my-usdt-balance:
	cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_MAINNET_RPC)

# 4) Transfer 1e4 (i.e. $0.01 USDC) to your HyperVault *directly* (does not hit "deposit", this is going into the abyss, so only use a few cents to test on Mainnet unless you are as rich as Scrooge McDuck)
transfer-to-contract:
	cast send $(USDT_MAINNET) "transfer(address,uint256)" $(HYPERVAULT) 1e4 --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# Now Check the HyperVault balance above again! (totalAssets should be == $0.01 USDC, or 1e4 USDT, now)

# 5) Approve HyperVault to transfer your USDT (1e18 plenty for testing)
approve-usdt-to-hypervault:
	cast send $(USDT_MAINNET) "approve(address,uint256)(bool)" $(HYPERVAULT) 1e18 --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# 6) Deposit USDT into HyperVault
deposit-usdt-to-hypervault:
	cast send $(HYPERVAULT) "deposit(uint256,address)(bool)" 1e4 $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# 7) Withdraw from Hypervault on HyperCore
withdraw-usdt-from-hypervault-on-core:
	cast send $(HYPERVAULT) "withdraw(uint256,address,address)(uint256)" 1e4 $(DEPLOYER_PUBLIC_ADDRESS) $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_MAINNET_RPC)

# GET ALL BALANCES:
#
# Gets your user/deployer USDT balance on HyperEVM, the HyperVault EVM balance, and the HyperVault totalAssets
# Uses cURL to get both your user/deployer token balances on HyperCore and the HyperVault token balances
# I use it to get a "global" idea of where the funds are, if they've landed on the HyperCore side, etc.
#
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



# Get Token Index
get-token-index-mainnet:
	cast call $(TOKEN_REGISTRY_MAINNET) "getTokenIndex(address)(uint32)" $(USDT_MAINNET) --rpc-url $(HYPEREVM_MAINNET_RPC)

get-hypervault-usdt-balance:
	cast call $(USDT_MAINNET) "balanceOf(address)(uint256)" $(HYPERVAULT) --rpc-url $(HYPEREVM_MAINNET_RPC)

# cURL to get HyperVault balance on Core
curl-get-hypervault-balance-on-core:
	curl -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(HYPERVAULT)"}'

curl-get-user-balance-on-core:
	curl -X POST https://api.hyperliquid.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(DEPLOYER_PUBLIC_ADDRESS)"}'

# TESTNET TOKEN REGISTRY COMMANDS...
set-token-testnet:
	cast send $(TOKEN_REGISTRY_TESTNET) "setTokenInfo(uint32)" 1129 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

get-usdc-token-index-testnet:
	cast call $(TOKEN_REGISTRY_TESTNET) "getTokenIndex(address)(uint32)" $(USDC_TESTNET) --rpc-url $(HYPEREVM_TESTNET_RPC)