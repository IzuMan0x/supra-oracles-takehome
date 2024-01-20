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

/// @title DecentralizedVotingSystem
/// @author Marquis
/// @notice Multiple Signature Wallet Where you can use multiple private keys to stage, confirm, and execute transactions for an added layer of security
contract MultiSigWallet {
    ////////////////////
    // Errors //////////
    ////////////////////
    error MultiSigWallet__CannotExecuteTransaction();
    error MultiSigWallet__TxFailed();
    error MultiSigWallet__TxNotConfirmed();
    error MultiSigWallet__AddressNotAnOwner();
    error MultiSigWallet__TxIndexDoesNotExist();
    error MultiSigWallet__TxAlreadyExecuted();
    error MultiSigWallet__TxAlreadyConfirmed();
    error MultiSigWallet__ThereMustBeAtLeastOneOwner();
    error MultiSigWallet__ConfirmationsMustBeGreaterThanZeroAndEqualToOrLessThanNumberOfOwners();
    error MultiSigWallet__OwnerMustBeValidAddress();
    error MultiSigWallet__OwnersMustBeUnique();
    ////////////////////
    // State Variables //
    ////////////////////

    address[] public s_owners;
    mapping(address => bool) public s_isOwner;
    uint256 public s_numberConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 value; //The amount to send from the wallet in ether
        bytes data; //Tx data, which for most cases can be blank ""
        bool executed; //bool whether the Tx has been executed
        uint256 numConfirmations; //current number of confirmations
    }

    // mapping from tx index => owner => bool
    // to keep track of who has confirmed what
    mapping(uint256 => mapping(address => bool)) public s_isConfirmed;

    Transaction[] public s_transactions;
    ////////////////////
    // Events //
    ////////////////////

    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    ////////////////////
    // Modifiers //
    ////////////////////

    modifier onlyOwner() {
        if (!s_isOwner[msg.sender]) {
            revert MultiSigWallet__AddressNotAnOwner();
        }
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= s_transactions.length) {
            revert MultiSigWallet__TxIndexDoesNotExist();
        }
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (s_transactions[_txIndex].executed) {
            revert MultiSigWallet__TxAlreadyExecuted();
        }
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (s_isConfirmed[_txIndex][msg.sender]) {
            revert MultiSigWallet__TxAlreadyConfirmed();
        }
        _;
    }

    /////////////
    //Functions//
    /////////////

    constructor(address[] memory _s_owners, uint256 _s_numberConfirmationsRequired) {
        if (_s_owners.length <= 0) {
            revert MultiSigWallet__ThereMustBeAtLeastOneOwner();
        } else if (_s_numberConfirmationsRequired <= 0 && _s_numberConfirmationsRequired > _s_owners.length) {
            revert MultiSigWallet__ConfirmationsMustBeGreaterThanZeroAndEqualToOrLessThanNumberOfOwners();
        }

        {
            for (uint256 i = 0; i < _s_owners.length; i++) {
                address owner = _s_owners[i];
                if (owner == address(0)) {
                    revert MultiSigWallet__OwnerMustBeValidAddress();
                } else if (s_isOwner[owner]) {
                    revert MultiSigWallet__OwnersMustBeUnique();
                }

                s_isOwner[owner] = true;
                s_owners.push(owner);
            }
        }

        s_numberConfirmationsRequired = _s_numberConfirmationsRequired;
    }
    /////////////////////
    //Fallback Function//
    ////////////////////

    //This is a fallback emit an event if ether is sent to the contract
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// @notice owner address can submit a Tx which later has to be confirmed by the other s_owners
    /// @dev The Tx data can be left blank ""
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public onlyOwner {
        uint256 txIndex = s_transactions.length;

        s_transactions.push(Transaction({to: _to, value: _value, data: _data, executed: false, numConfirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }
    /// @notice s_owners can confirm current pending s_transactions
    /// @dev An owner can only confirm once and it can confirm can confirm an address it has submitted itself

    function confirmTransaction(uint256 _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = s_transactions[_txIndex];
        transaction.numConfirmations += 1;
        s_isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /// @notice Once a Transaction has reached the minimum amount of required confirmations it can be executed
    function executeTransaction(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = s_transactions[_txIndex];

        if (transaction.numConfirmations < s_numberConfirmationsRequired) {
            revert MultiSigWallet__CannotExecuteTransaction();
        }

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        if (!success) {
            revert MultiSigWallet__TxFailed();
        }

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /// @notice An owner can revoke its confirmation
    function revokeConfirmation(uint256 _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = s_transactions[_txIndex];

        if (s_isConfirmed[_txIndex][msg.sender] != true) {
            revert MultiSigWallet__TxNotConfirmed();
        }
        transaction.numConfirmations -= 1;
        s_isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }
    /// @notice returns an an array of addresses for the multisig s_owners

    function getOwners() public view returns (address[] memory) {
        return s_owners;
    }

    /// @notice returns the amount of s_transactions
    function getTransactionCount() public view returns (uint256) {
        return s_transactions.length;
    }

    /// @notice returns the transaction details in the s_transactions struct
    function getTransaction(uint256 _txIndex)
        public
        view
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations)
    {
        Transaction storage transaction = s_transactions[_txIndex];

        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }
}
