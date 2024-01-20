// SPDX-License-Identifier: Unlicensed

// version
// imports
// interfaces, libraries, contracts
// Layout of Contract:
// errors
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title TokenSwap
/// @author Marquis
/// @notice A simple ERC20 token swap where you can trade tokenA for tokenB and vice-versa at a pre-defined exchange rate that is defined when the contract is deployed.
/// @notice Only supports the swapping between two tokens defined at deployment/constructor.
/// @notice There is a chance for the contract to become quickly illiquid with a fixed rate.
contract TokenSwap is ReentrancyGuard {
    ////////////////////
    // Errors /////////
    ////////////////////
    error TokenSwap__AllowanceTooLow(uint256 currentTokenAllowance);
    error TokenSwap__TokenAddressNotSwappable();
    error TokenSwap__TransferFailed();

    ////////////////////
    // Sate Variables //
    ////////////////////

    IERC20 public s_tokenA;
    IERC20 public s_tokenB;
    uint256 public s_exchangeRate;

    ////////////////////
    // Events /////////
    ////////////////////

    event TokenSwapped(address indexed forAddress, uint256 indexed amount);

    constructor(address tokenA, address tokenB, uint256 exchangeRate) {
        s_tokenA = IERC20(tokenA);
        s_tokenB = IERC20(tokenB);
        s_exchangeRate = exchangeRate; //tokenA to tokenB
    }

    function swap(address tokenAddress, uint256 amount) public nonReentrant {
        if (tokenAddress != address(s_tokenA) && tokenAddress != address(s_tokenB)) {
            revert TokenSwap__TokenAddressNotSwappable();
        } else if (IERC20(tokenAddress).allowance(msg.sender, address(this)) <= amount) {
            revert TokenSwap__AllowanceTooLow(IERC20(tokenAddress).allowance(msg.sender, address(this)));
        }

        if (tokenAddress == address(s_tokenA)) {
            _safeTransferFrom(s_tokenA, msg.sender, address(this), amount);

            s_tokenB.transfer(msg.sender, amount * s_exchangeRate);

            emit TokenSwapped(tokenAddress, amount * s_exchangeRate);
        } else if (tokenAddress == address(s_tokenB)) {
            _safeTransferFrom(s_tokenB, msg.sender, address(this), amount);

            s_tokenA.transfer(msg.sender, amount / s_exchangeRate);

            emit TokenSwapped(tokenAddress, amount / s_exchangeRate);
        }
    }

    function _safeTransferFrom(IERC20 token, address sender, address recipient, uint256 amount) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        if (!sent) {
            revert TokenSwap__TransferFailed();
        }
    }
}
