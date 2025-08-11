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
        // bridge USDC to HyperCore Spot
        CoreWriterLib.bridgeToCore(address(asset), assets);

        // // get USDC tokenId from address
        // uint64 tokenId = PrecompileLib.getTokenIndex(address(asset));

        // // calculate coreAmount from evmAmount
        // uint64 coreAmount = HLConversions.convertEvmToCoreAmount(tokenId, assets);

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
        uint256 hyperEvmBalance = asset.balanceOf(address(this)); // HyperEVM USDC Balance
        PrecompileLib.UserVaultEquity memory vaultEquity = PrecompileLib.userVaultEquity(address(this), vault);
        return vaultEquity.equity + hyperEvmBalance;
    }

    receive() external payable {}
}