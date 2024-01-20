// SPDX-LicenseIdentifier: UNLICENSED

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {DeployMultiSigWallet} from "../script/DeployMultiSigWallet.s.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public multiSigWallet;
    uint256 deployerKey;
    uint256 account1;
    uint256 account2;

    address recievingWallet = makeAddr("recievingWallet");
    address hacker = makeAddr("hacker");

    function setUp() public {
        DeployMultiSigWallet deployer = new DeployMultiSigWallet();
        (multiSigWallet, deployerKey, account1, account2) = deployer.run();

        vm.deal(address(multiSigWallet), 1_000 ether);
    }

    function testIfATransactionCanBeSubmittedAndExecuted() public {
        vm.startPrank(vm.addr(deployerKey));

        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(vm.addr(account1));
        multiSigWallet.getTransaction(0);
        multiSigWallet.confirmTransaction(0);
        multiSigWallet.executeTransaction(0);
        assertEq(recievingWallet.balance, 5 ether);
        vm.stopPrank();
    }

    function testWillRevertIfNonOwnerSubmitsATransaction() public {
        vm.startPrank(hacker);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__AddressNotAnOwner.selector);
        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");

        vm.stopPrank();
    }

    function testWillRevertIfNonOwnerConfirmsATransaction() public {
        vm.startPrank(vm.addr(deployerKey));

        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(hacker);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__AddressNotAnOwner.selector);
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();
    }

    function testWillRevertIfRequiredConfirmationsIsNotReached() public {
        vm.startPrank(vm.addr(deployerKey));
        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");
        multiSigWallet.confirmTransaction(0);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__CannotExecuteTransaction.selector);
        multiSigWallet.executeTransaction(0);
        vm.stopPrank();
    }

    function testWillRevertIfTheTxIndexDoesNotExist() public {
        vm.startPrank(vm.addr(deployerKey));
        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");
        vm.expectRevert(MultiSigWallet.MultiSigWallet__TxIndexDoesNotExist.selector);
        multiSigWallet.confirmTransaction(1);

        vm.stopPrank();
    }

    function testWillRevertIfTheOwnerAlreadyConfirmedTheTransaction() public {
        vm.startPrank(vm.addr(deployerKey));
        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");

        multiSigWallet.confirmTransaction(0);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__TxAlreadyConfirmed.selector);
        multiSigWallet.confirmTransaction(0);

        vm.stopPrank();
    }

    function testWillRevertIfExecutingTxThatHasAlreadyBeenExecuted() public {
        vm.startPrank(vm.addr(deployerKey));

        multiSigWallet.submitTransaction(recievingWallet, 5 ether, "");
        multiSigWallet.confirmTransaction(0);
        vm.stopPrank();

        vm.startPrank(vm.addr(account1));
        multiSigWallet.getTransaction(0);
        multiSigWallet.confirmTransaction(0);
        multiSigWallet.executeTransaction(0);
        //assertEq(recievingWallet.balance, 5 ether);
        vm.expectRevert(MultiSigWallet.MultiSigWallet__TxAlreadyExecuted.selector);
        multiSigWallet.executeTransaction(0);
        vm.stopPrank();
    }

    function testGetMultiSigWalletOwners() public {
        vm.startPrank(vm.addr(deployerKey));

        multiSigWallet.getOwners();

        vm.stopPrank();
    }
}
