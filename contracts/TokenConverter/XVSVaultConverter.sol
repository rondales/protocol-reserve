// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.13;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { ResilientOracle } from "@venusprotocol/oracle/contracts/ResilientOracle.sol";

import { AbstractTokenConverter } from "./AbstractTokenConverter.sol";
import { ensureNonzeroAddress } from "../Utils/Validators.sol";

/// @title XVSVaultConverter
/// @author Venus
/// @notice XVSVaultConverter used for token conversions and sends received token to XVSVaultTreasury
/// @custom:security-contact https://github.com/VenusProtocol/protocol-reserve#discussion
contract XVSVaultConverter is AbstractTokenConverter {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @notice Address of the XVS token
    address public immutable XVS;

    /// @notice Emmitted after the funds transferred to the destination address
    event XVSTransferredToDestination(uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    /// @param xvs_ Address of the XVS token
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address xvs_) {
        ensureNonzeroAddress(xvs_);
        XVS = xvs_;

        // Note that the contract is upgradeable. Use initialize() or reinitializers
        // to set the state variables.
        _disableInitializers();
    }

    /// @param accessControlManager_ Access control manager contract address
    /// @param priceOracle_ Resilient oracle address
    /// @param destinationAddress_  Address at all incoming tokens will transferred to
    function initialize(
        address accessControlManager_,
        ResilientOracle priceOracle_,
        address destinationAddress_
    ) public initializer {
        // Initialize AbstractTokenConverter
        __AbstractTokenConverter_init(accessControlManager_, priceOracle_, destinationAddress_);
    }

    /// @dev This function is called by protocolShareReserve
    /// @param comptroller Comptroller address (pool)
    /// @param asset Asset address.
    // solhint-disable-next-line
    function updateAssetsState(address comptroller, address asset) public {
        uint256 xvsBalance;
        if (asset == XVS) {
            IERC20Upgradeable token = IERC20Upgradeable(XVS);
            xvsBalance = token.balanceOf(address(this));

            token.safeTransfer(destinationAddress, xvsBalance);
        }

        emit XVSTransferredToDestination(xvsBalance);
    }

    /// @notice Get the balance for specific token
    /// @param tokenAddress Address of the token
    /// @return tokenBalance Balance of the token the contract has
    function balanceOf(address tokenAddress) public view override returns (uint256 tokenBalance) {
        IERC20Upgradeable token = IERC20Upgradeable(tokenAddress);
        tokenBalance = token.balanceOf(address(this));
    }

    /// @notice Get base asset address
    function _getDestinationBaseAsset() internal view override returns (address) {
        return XVS;
    }
}
