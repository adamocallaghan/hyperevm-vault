// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC4626} from "solmate/tokens/ERC4626.sol";
import {CoreWriterLib, HLConversions} from "@hyper-evm-lib/src/CoreWriterLib.sol";
import {PrecompileLib} from "@hyper-evm-lib/src/PrecompileLib.sol";

/**
 * @title HyperVault
 * @dev ERC4626 vault to tokenise vaults/staking on HyperCore
 */
contract HyperVault is ERC4626 {
    using CoreWriterLib for *;

    uint64 public constant USDC_TOKEN_ID = 0;

    /*//////////////////////////////////////////////////////////////
                    Hooks for Basic Vault Operations
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {
        CoreWriterLib.vaultTransfer(vault, false, usdcAmount);
    }

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {
        CoreWriterLib.vaultTransfer(vault, true, usdcAmount);
    }

    /*//////////////////////////////////////////////////////////////
                        Vault Information
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        PrecompileLib.UserVaultEquity memory vaultEquity = PrecompileLib.userVaultEquity(address(this), vault);
        return vaultEquity.equity;
    }

    receive() external payable {}
}