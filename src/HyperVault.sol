// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626} from "solmate/tokens/ERC4626.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {CoreWriterLib, HLConversions} from "@hyper-evm-lib/src/CoreWriterLib.sol";
import {PrecompileLib} from "@hyper-evm-lib/src/PrecompileLib.sol";

/**
 * @title HyperVault
 * @dev ERC4626 vault to tokenise vaults/staking on HyperCore
 */
contract HyperVault is ERC4626 {
    using CoreWriterLib for *;

    uint64 public constant USDC_TOKEN_ID = 0;
    address public vault;

    uint256 public totalAssetsEvmCount;

    constructor(address _vault, ERC20 _token, string memory _name, string memory _symbol) ERC4626(_token, _name, _symbol){
        vault = _vault;
    }

    /*//////////////////////////////////////////////////////////////
                    Hooks for Basic Vault Operations
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        CoreWriterLib.vaultTransfer(vault, false, uint64(assets));
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        // temporary til all CoreWriter and Precompile funcs are working correctly
        totalAssetsEvmCount = totalAssetsEvmCount + assets;

        // bridge USDT to HyperCore Spot
        CoreWriterLib.bridgeToCore(address(asset), assets);

        // get USDT tokenId from address
        uint64 tokenId = PrecompileLib.getTokenIndex(address(asset));

        // calculate coreAmount from evmAmount
        uint64 coreAmount = HLConversions.convertEvmToCoreAmount(tokenId, assets);

        // transfer to HLP vault
        CoreWriterLib.vaultTransfer(vault, true, coreAmount);

        // CoreWriterLib.spotSend(msg.sender, tokenId, coreAmount); // transfer to the user on Core Spot

        // uint32 spotPairAsset = 10166;
        // bool isBuy = false; // buy 'base' token = true; buy 'quote' token = false; we are buying USDC, the quote token
        // uint64 limitPx = 0;
        // // uint64 sz;
        // bool reduceOnly = false;
        // uint8 encodedTif = 3; // 3 = IOC, should act as a market order
        // uint128 cloid = 0; // No CLOID for demo

        // // swap USDT to USDC (Spot)
        // CoreWriterLib.placeLimitOrder(spotPairAsset, isBuy, limitPx, coreAmount, reduceOnly, encodedTif, cloid);

        // // transfer USDC from Spot to Perps
        // uint64 usdcPerpAmount = HLConversions.convertUSDC_CoreToPerp(coreAmount);
        // CoreWriterLib.transferUsdClass(usdcPerpAmount, true);

        // // transfer to the HLP vault
        // CoreWriterLib.vaultTransfer(vault, true, uint64(assets));
    }

    function getTokenIndex(address _tokenAddress) public view returns(uint64) {
        return PrecompileLib.getSpotIndex(_tokenAddress);
    }

    /*//////////////////////////////////////////////////////////////
                        Vault Information
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return totalAssetsEvmCount;
        // uint256 hyperEvmBalance = asset.balanceOf(address(this)); // HyperEVM USDC Balance
        // PrecompileLib.UserVaultEquity memory vaultEquity = PrecompileLib.userVaultEquity(address(this), vault);
        // PrecompileLib.SpotBalance memory spotBalance = PrecompileLib.spotBalance(address(this), asset);
        // return vaultEquity.equity + spotBalance.total + hyperEvmBalance;
    }

    receive() external payable {}
}