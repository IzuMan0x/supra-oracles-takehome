// SPDX-LicenseIdentifier: UNLICENSED

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {TokenSale} from "../src/TokenSale.sol";
import {DeployTokenSale} from "../script/DeployTokenSale.s.sol";

contract TokenSaleTest is Test {
    TokenSale public tokenSale;
    address tokenAddress;

    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(deployerKey);

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        DeployTokenSale deployer = new DeployTokenSale();
        (tokenSale, tokenAddress) = deployer.run();

        vm.deal(user1, 1_000 ether);
        vm.deal(user2, 1_000 ether);

        vm.startPrank(deployerAddress);
        tokenSale.openPreSale();
        vm.stopPrank();
    }

    function testIfAddressCanPurchase() public {
        vm.startPrank(user1);
        tokenSale.contributePreSale{value: 5 ether}();
        vm.stopPrank();
    }

    //vm.expectRevert(abi.encodeWithSelector(TokenSwap.TokenSwap__AllowanceTooLow.selector, 0));

    function testWillRevertIfPreSaleContributionLimitReached() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(TokenSale.TokenSale__MaxContributionLimitReached.selector, 10 ether, 100 ether)
        );
        tokenSale.contributePreSale{value: 100 ether}();
        vm.stopPrank();
    }

    function testWillReverIfContributionIsLessThanMin() public {
        vm.startPrank(user1);
        vm.expectRevert(
            abi.encodeWithSelector(TokenSale.TokenSale__MinContributionAmountNotReached.selector, 1 ether, 0.5 ether)
        );
        tokenSale.contributePreSale{value: 0.5 ether}();
        vm.stopPrank();
    }

    function testWillRevertIfPreAndPublicSaleAreClosedAndUserContributes() public {
        vm.startPrank(deployerAddress);
        tokenSale.openPreSale();
        tokenSale.openPublicSale();
        vm.stopPrank();
        vm.startPrank(user1);
        vm.expectRevert(TokenSale.TokenSale__PreSaleNotOpen.selector);
        tokenSale.contributePreSale{value: 5 ether}();
        vm.stopPrank();
    }

    function testOwnerCanDistributeTokens() public {
        vm.startPrank(deployerAddress);
        tokenSale.distributeTokens(tokenAddress, 100 ether, deployerAddress);

        vm.stopPrank();
    }

    function testUserCanGetRefundIfMinNotMet() public {
        vm.startPrank(user1);

        tokenSale.contributePreSale{value: 5 ether}();

        vm.stopPrank();

        vm.startPrank(deployerAddress);

        tokenSale.closePreSale();
        vm.stopPrank();

        vm.startPrank(user1);

        tokenSale.refund();

        vm.stopPrank();
    }

    function testWillRevertIsSaleIsLiveAndUserRefunds() public {
        vm.startPrank(user1);

        tokenSale.contributePreSale{value: 5 ether}();

        vm.expectRevert(TokenSale.TokenSale__UnableToRefundWhileSaleIsLive.selector);
        tokenSale.refund();

        vm.stopPrank();
    }
}
