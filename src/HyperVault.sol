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
        // calculate coreSharesAmount from evmAmount
        uint64 coreAmount = uint64(shares * (10 ** uint8(-0)));

        // calculate per amount from core
        uint64 usdcPerpAmount = coreAmount / 10 ** 2;

        // transfer from the HLP vault
        CoreWriterLib.vaultTransfer(vault, false, usdcPerpAmount);

        // CoreWriterLib.transferUsdClass(usdcPerpAmount, false);

        // USDC tokenId
        // uint64 tokenId = 0;

        // CoreWriterLib.spotSend(msg.sender, tokenId, coreAmount);
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override {
        // temporary til all CoreWriter and Precompile funcs are working correctly
        totalAssetsEvmCount = totalAssetsEvmCount + assets;

        // bridge USDT to HyperCore Spot
        CoreWriterLib.bridgeToCore(address(asset), assets);

        // USDC tokenId
        uint64 tokenId = 0; // Hardcoding due to Precompile revert

        // calculate coreAmount from evmAmount
        // uint64 coreAmount = HLConversions.convertEvmToCoreAmount(tokenId, assets);
        uint64 coreAmount = uint64(assets * (10 ** uint8(-0)));

        // transfer USDC from Spot to Perps
        uint64 usdcPerpAmount = coreAmount / 10 ** 2;
        CoreWriterLib.transferUsdClass(usdcPerpAmount, true);

        // transfer to the HLP vault
        CoreWriterLib.vaultTransfer(vault, true, uint64(usdcPerpAmount));
    }

    function getTokenIndex(address _tokenAddress) public view returns(uint64) {
        return PrecompileLib.getSpotIndex(_tokenAddress);
    }

    function withdrawFromVault(address vault, uint64 usdcAmount) external {
        CoreWriterLib.vaultTransfer(vault, false, usdcAmount);
    }

    function depositToVault(address vault, uint64 usdcAmount) external {
        CoreWriterLib.vaultTransfer(vault, true, usdcAmount);
    }

    function usdcClassTransferPerpsToSpot(uint64 usdcPerpAmount) external {
        CoreWriterLib.transferUsdClass(usdcPerpAmount, false);
    }

    function usdcClassTransferSpotToPerps(uint64 usdcPerpAmount) external {
        CoreWriterLib.transferUsdClass(usdcPerpAmount, true);
    }

    function bridgeAssetsToCore(uint256 assets) external {
        CoreWriterLib.bridgeToCore(address(asset), assets);
    }

    function withdrawTest(
        uint256 assets,
        address receiver,
        address owner
    ) public returns (uint256 shares) {
        beforeWithdraw(assets, assets);

        _burn(owner, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, assets);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        // note: leaving this for visibility; in a standard chain
        // ERC4626 vault our final step would be to transfer the
        // assets over to the user. However, our assets are not on
        // the HyperEVM here, they are on Core, and we will transfer
        // them to the user there using spotSend instead
        //
        // asset.safeTransfer(receiver, assets);
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