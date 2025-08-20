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
	cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)

# USDT vs USDC NOTE: there is no linked USDC on HyperEVM Mainnet yet, only on Testnet
# I hope to get around to adding swap functionality that allows you to deposit USDT
# on Mainnet, bridge + swap using an IOC limit order

# 3) Check your USDC balance on HyperEVM Testnet
get-my-usdc-balance:
	cast call $(USDC_TESTNET) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_TESTNET_RPC)

# 4) Transfer 1e8 (i.e. $! USDC) to your HyperVault *directly* (does not hit "deposit", this is going into the abyss)
transfer-to-contract:
	cast send $(USDC_TESTNET) "transfer(address,uint256)" $(HYPERVAULT) 1e8 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# Now Check the HyperVault totalAssets balance above again! (totalAssets should be == $1 USDC, or 1e8 USDC, now)

# 5) Approve HyperVault to transfer your USDC (1e18 plenty for testing)
approve-usdc-to-hypervault:
	cast send $(USDC_TESTNET) "approve(address,uint256)(bool)" $(HYPERVAULT) 1e18 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# 6) Deposit USDC into HyperVault (*showtime* - this will bridge to HyperCore + deposit into HLP vault)
deposit-usdc-to-hypervault:
	cast send $(HYPERVAULT) "deposit(uint256,address)(bool)" 6e8 $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# 7) Withdraw from Hypervault on HyperCore
withdraw-usdt-from-hypervault-on-core:
	cast send $(HYPERVAULT) "withdraw(uint256,address,address)(uint256)" 6e8 $(DEPLOYER_PUBLIC_ADDRESS) $(DEPLOYER_PUBLIC_ADDRESS) --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

# GET ALL BALANCES:
#
# Gets your user/deployer USDT balance on HyperEVM, the HyperVault EVM balance, and the HyperVault totalAssets
# Uses cURL to get both your user/deployer token balances on HyperCore and the HyperVault token balances
# I use it to get a "global" idea of where the funds are, if they've landed on the HyperCore side, etc.
#
get-all-balances:
	@echo "Fetching HyperEVM Testnet Balances..."
	@total_assets=$$(cast call $(HYPERVAULT) "totalAssets()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)); \
	my_usdc=$$(cast call $(USDC_TESTNET) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_TESTNET_RPC)); \
	hypervault_usdc=$$(cast call $(USDC_TESTNET) "balanceOf(address)(uint256)" $(HYPERVAULT) --rpc-url $(HYPEREVM_TESTNET_RPC)); \
	echo "HyperVault - Total Deposited Assets: $$total_assets"; \
 	echo "HyperVault - USDC Balance: $$hypervault_usdc"; \
	echo "User/Deployer Wallet - USDC Balance: $$my_usdc"; \
	\
	echo ""; \
	echo "Fetching HyperVault balances from HyperLiquid Core..."; \
	hv_core=$$(curl -s -X POST https://api.hyperliquid-testnet.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(HYPERVAULT)"}'); \
	echo "$$hv_core" | jq -r '.balances[] | "\(.coin): \(.total)"'; \
	\
	echo ""; \
	echo "Fetching User/Deployer balances from HyperLiquid Core..."; \
	user_core=$$(curl -s -X POST https://api.hyperliquid-testnet.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(DEPLOYER_PUBLIC_ADDRESS)"}'); \
	echo "$$user_core" | jq -r '.balances[] | "\(.coin): \(.total)"'; \
	\
	echo ""; \
	echo "Fetching HyperVault HLP Vault Equity..."; \
	hlp_equity=$$(curl -s -X POST https://api.hyperliquid-testnet.xyz/info \
  	-H "Content-Type: application/json" \
  	-d '{"type": "userVaultEquities","user": "$(HYPERVAULT)"}' \
  	| jq -r '.[] | select(.vaultAddress=="0xa15099a30bbf2e68942d6f4c43d70d04faeab0a0") | .equity'); \
	echo "HLP Vault Equity: $$hlp_equity"; \
	\
	echo ""; \
	echo "Fetching Random Vault Equity..."; \
	random_vault_equity=$$(curl -s -X POST https://api.hyperliquid-testnet.xyz/info \
  	-H "Content-Type: application/json" \
  	-d '{"type": "userVaultEquities","user": "$(HYPERVAULT)"}' \
  	| jq -r '.[] | select(.vaultAddress=="0x3ea541c902e9da1679b1f0422d30594a81fbc398") | .equity'); \
	echo "Random Vault Equity: $$random_vault_equity"





# Get Hypervault Deposit 'asset'
get-hypervault-deposit-asset:
	cast call $(HYPERVAULT) "asset()(address)" --rpc-url $(HYPEREVM_TESTNET_RPC)

# Get the HLP vault equity + unlock time for the HyperVault contract address
# *** RUN THIS COMMAND DIRECTLY IN SHELL ***
# cast call 0x0000000000000000000000000000000000000802 --rpc-url $HYPEREVM_TESTNET_RPC --data $(cast abi-encode "f(address,address)" $HYPERVAULT $HLP_VAULT_TESTNET) | xargs -I{} cast abi-decode "f()(uint64,uint64)" {}

# Get Token Index
get-token-index-mainnet:
	cast call $(TOKEN_REGISTRY_MAINNET) "getTokenIndex(address)(uint32)" $(USDT_MAINNET) --rpc-url $(HYPEREVM_MAINNET_RPC)

# shares, totalSupply and totalAssetsEvmCount commands

get-my-hypervault-shares-balance:
	cast call $(HYPERVAULT) "balanceOf(address)(uint256)" $(DEPLOYER_PUBLIC_ADDRESS) --rpc-url $(HYPEREVM_TESTNET_RPC)

get-hypervault-shares-total-supply:
	cast call $(HYPERVAULT) "totalSupply()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)

get-hypervault-total-asset-evm-count:
	cast call $(HYPERVAULT) "totalAssetsEvmCount()(uint256)" --rpc-url $(HYPEREVM_TESTNET_RPC)

# cURL to get HyperVault balance on Core
curl-get-hypervault-balance-on-core:
	curl -X POST https://api.hyperliquid-testnet.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(HYPERVAULT)"}'

curl-get-user-balance-on-core:
	curl -X POST https://api.hyperliquid-testnet.xyz/info -H "Content-Type: application/json" -d '{"type": "spotClearinghouseState","user": "$(DEPLOYER_PUBLIC_ADDRESS)"}'

curl-get-user-hlp-vault-equity:
	curl -X POST https://api.hyperliquid-testnet.xyz/info -H "Content-Type: application/json" -d '{"type": "userVaultEquities","user": "$(HYPERVAULT)"}'

# TESTNET TOKEN REGISTRY COMMANDS...
set-token-testnet:
	cast send $(TOKEN_REGISTRY_TESTNET) "setTokenInfo(uint32)" 1129 --account deployer --rpc-url $(HYPEREVM_TESTNET_RPC)

get-usdc-token-index-testnet:
	cast call $(TOKEN_REGISTRY_TESTNET) "getTokenIndex(address)(uint32)" $(USDC_TESTNET) --rpc-url $(HYPEREVM_TESTNET_RPC)