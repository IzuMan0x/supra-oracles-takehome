// SPDX-License-Identifier: UNLICENSED

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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title TokenSale
/// @author Marquis
/// @notice This is a token sale contract where the token can be purchsed 1:1 for ethereum
/// @notice There is a preSale and a publicSale which have min and max amounts. If max no more tokens will be sold and min is not reached after the end of the sale, users can claim a refund.
/// @notice The start and changing between preSale and publicSale are all handled manually by the owner wallet which by default is the deployer of the contract
contract TokenSale is Ownable, ReentrancyGuard {
    ////////////////////
    // Errors //////////
    ////////////////////
    error TokenSale__TokenAddressIsNotValid();
    error TokenSale__MinContributionAmountNotReached(uint256 minAmount, uint256 attemptedContributions);
    error TokenSale__MaxContributionLimitReached(uint256 maxAmount, uint256 attemptedContributions);
    error TokenSale__TransferFailed();
    error TokenSale__TotalMaxContributionsForPublicSaleReached(
        uint256 currentTotalContributions, uint256 maxContributionsAllowed
    );
    error TokenSale__TotalMaxContributionsForPreSaleReached(
        uint256 currentTotalContributions, uint256 maxContributionsAllowed
    );
    error TokenSale__MinContributionsMetRefundNotAvailable();
    error TokenSale__CannotStartPreSaleWhilePublicSaleIsOpen();
    error TokenSale__CannotStartPublicSaleWhilePublicSaleIsOpen();
    error TokenSale__PublicSaleNotOpen();
    error TokenSale__PreSaleNotOpen();
    error TokenSale__UnableToRefundWhileSaleIsLive();
    error TokenSale__AddressHasContributedAnything();
    error TokenSale__PreSaleCannotBeClosed();
    error TokenSale__PublicSaleCannotBeClosed();

    ////////////////////
    // State Variables //
    ////////////////////
    address private s_tokenAddress;
    //pre Sale
    bool private s_preSaleOpen;
    uint256 private s_preSaleCurrentContributions;
    uint256 private s_preSaleMinTotalCap;
    uint256 private s_preSaleMaxTotalCap;
    uint256 private s_preSaleMinContribution;
    uint256 private s_preSaleMaxContribution;
    mapping(address userAddress => uint256 amountContributed) private s_preSaleAmountContributed;

    //Public Sale
    bool private s_publicSaleOpen;
    uint256 private s_publicSaleCurrentContributions;
    uint256 private s_publicSaleMinTotalCap;
    uint256 private s_publicSaleMaxTotalCap;
    uint256 private s_publicSaleMinContribution;
    uint256 private s_publicSaleMaxContribution;
    mapping(address userAddress => uint256 amountContributed) private s_publicSaleAmountContributed;

    ////////////////////
    // Events /////////
    ///////////////////
    event PreSaleContribution(address indexed userAddress, uint256 indexed amount);
    event PublicSaleContribution(address indexed userAddress, uint256 indexed amount);
    event ContributionsRefunded(address indexed userAddress, uint256 indexed refundAmount);
    event PreSaleOpened(uint256 indexed time, address indexed owner);
    event PublicSaleOpened(uint256 indexed time, address indexed owner);
    event PreSaleClosed(uint256 indexed time, address indexed owner);
    event PublicSaleClosed(uint256 indexed time, address indexed owner);

    ////////////////////
    // Functions //////
    ///////////////////

    constructor(
        //owner address
        address ownerAddress,
        //Token Address
        address tokenAddress,
        //pre-sale
        uint256 preSaleMinTotalCap,
        uint256 preSaleMaxTotalCap,
        uint256 preSaleMinContribution,
        uint256 preSaleMaxContribution,
        //public-sale
        uint256 publicSaleMaxTotalCap,
        uint256 publicSaleMinTotalCap,
        uint256 publicSaleMinContribution,
        uint256 publicSaleMaxContribution
    ) Ownable(ownerAddress) {
        if (address(tokenAddress) == address(0)) {
            revert TokenSale__TokenAddressIsNotValid();
        } else {
            s_tokenAddress = tokenAddress;
        }

        s_publicSaleOpen = false;
        s_preSaleOpen = false;

        //pre
        s_preSaleMinTotalCap = preSaleMinTotalCap;
        s_preSaleMaxTotalCap = preSaleMaxTotalCap;
        s_preSaleMinContribution = preSaleMinContribution;
        s_preSaleMaxContribution = preSaleMaxContribution;
        //public
        s_publicSaleMinTotalCap = publicSaleMinTotalCap;
        s_publicSaleMaxTotalCap = publicSaleMaxTotalCap;
        s_publicSaleMinContribution = publicSaleMinContribution;
        s_publicSaleMaxContribution = publicSaleMaxContribution;
    }
    /// @notice Opens the preSale

    function openPreSale() external onlyOwner {
        if (s_publicSaleOpen == true) {
            revert TokenSale__CannotStartPreSaleWhilePublicSaleIsOpen();
        } else {
            s_preSaleOpen = true;
            emit PreSaleOpened(block.timestamp, msg.sender);
        }
    }

    /// @notice Closes the preSale
    function closePreSale() external onlyOwner {
        if (s_publicSaleOpen == true || s_preSaleOpen == false) {
            revert TokenSale__PreSaleCannotBeClosed();
        }
        s_preSaleOpen = false;
        emit PreSaleClosed(block.timestamp, msg.sender);
    }

    /// @notice Opens the Public Sale
    function openPublicSale() external onlyOwner {
        if (s_publicSaleOpen == true) {
            revert TokenSale__CannotStartPublicSaleWhilePublicSaleIsOpen();
        } else {
            s_preSaleOpen = false;
            s_publicSaleOpen = true;
            emit PreSaleClosed(block.timestamp, msg.sender);
            emit PublicSaleOpened(block.timestamp, msg.sender);
        }
    }

    /// @notice Closes the Public Sale
    function closePublicSale() external onlyOwner {
        if (s_publicSaleOpen == false || s_preSaleOpen == true) {
            revert TokenSale__PublicSaleCannotBeClosed();
        } else {
            s_publicSaleOpen = false;
            emit PublicSaleClosed(block.timestamp, msg.sender);
        }
    }

    /// @notice preSale users can buy tokens for a 1:1 exchange between ether
    function contributePreSale() public payable nonReentrant {
        if (!s_preSaleOpen) {
            revert TokenSale__PreSaleNotOpen();
        }
        if ((msg.value + s_preSaleAmountContributed[msg.sender]) < s_preSaleMinContribution) {
            revert TokenSale__MinContributionAmountNotReached(s_preSaleMinContribution, msg.value);
        } else if ((msg.value + s_preSaleAmountContributed[msg.sender]) > s_preSaleMaxContribution) {
            revert TokenSale__MaxContributionLimitReached(s_preSaleMaxContribution, msg.value);
        }

        if ((msg.value + s_preSaleCurrentContributions) > s_preSaleMaxTotalCap) {
            revert TokenSale__TotalMaxContributionsForPreSaleReached(
                s_preSaleCurrentContributions, s_preSaleMaxTotalCap
            );
        }

        s_preSaleAmountContributed[msg.sender] += msg.value;
        bool success = IERC20(s_tokenAddress).transfer(msg.sender, msg.value);
        if (!success) {
            revert TokenSale__TransferFailed();
        }
        emit PreSaleContribution(msg.sender, msg.value);
    }

    ///@notice users can buy tokens for a 1:1 exchange between ether
    function contributePublicSale() public payable nonReentrant {
        if (!s_publicSaleOpen) {
            revert TokenSale__PublicSaleNotOpen();
        }
        if ((msg.value + s_publicSaleAmountContributed[msg.sender]) < s_publicSaleMinContribution) {
            revert TokenSale__MinContributionAmountNotReached(s_publicSaleMinContribution, msg.value);
        } else if ((msg.value + s_publicSaleAmountContributed[msg.sender]) > s_publicSaleMaxContribution) {
            revert TokenSale__MaxContributionLimitReached(s_publicSaleMaxContribution, msg.value);
        }
        if ((msg.value + s_publicSaleCurrentContributions) > s_publicSaleMaxTotalCap) {
            revert TokenSale__TotalMaxContributionsForPublicSaleReached(
                s_publicSaleCurrentContributions, s_publicSaleMaxTotalCap
            );
        }

        s_publicSaleAmountContributed[msg.sender] += msg.value;
        bool success = IERC20(s_tokenAddress).transfer(msg.sender, msg.value);
        if (!success) {
            revert TokenSale__TransferFailed();
        }
        emit PublicSaleContribution(msg.sender, msg.value);
    }

    /// @notice user can claim a refund if the minimum is not reached for both preSale and publicSale
    /// @dev both the preSale and publicSale must be closed for a user to claim a arefund
    function refund() external nonReentrant {
        if (s_preSaleOpen == true || s_publicSaleOpen == true) {
            revert TokenSale__UnableToRefundWhileSaleIsLive();
        }
        if (
            s_preSaleCurrentContributions >= s_preSaleMinTotalCap
                || s_publicSaleCurrentContributions >= s_publicSaleMinTotalCap
        ) {
            revert TokenSale__MinContributionsMetRefundNotAvailable();
        }

        uint256 refundAmount = s_publicSaleAmountContributed[msg.sender] + s_preSaleAmountContributed[msg.sender];
        if (refundAmount == 0) {
            revert TokenSale__AddressHasContributedAnything();
        }
        delete s_preSaleAmountContributed[msg.sender];
        delete s_publicSaleAmountContributed[msg.sender];
        (bool sent,) = payable(msg.sender).call{value: refundAmount}("");
        if (!sent) {
            revert TokenSale__TransferFailed();
        }
        emit ContributionsRefunded(msg.sender, refundAmount);
    }

    /// @notice Transfers any ERC20 from the contract and can only called by the owner
    function distributeTokens(address tokenAddress, uint256 amount, address transferAddress)
        external
        nonReentrant
        onlyOwner
    {
        bool success = IERC20(tokenAddress).transfer(transferAddress, amount);
        if (!success) {
            revert TokenSale__TransferFailed();
        }
    }

    function withdraw() external nonReentrant onlyOwner {
        (bool sent,) = payable(msg.sender).call{value: address(this).balance}("");
        if (!sent) {
            revert TokenSale__TransferFailed();
        }
    }
}
