// SPDX-LicenseIdentifier: UNLICENSED

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {TokenSwap} from "../src/TokenSwap.sol";
import {DeployTokenSwap} from "../script/DeployTokenSwap.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract TokenSaleTest is Test {
    TokenSwap public tokenSwap;

    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(deployerKey);

    address addressTokenA;
    address addressTokenB;

    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");

    function setUp() public {
        DeployTokenSwap deployer = new DeployTokenSwap();
        (tokenSwap, addressTokenA, addressTokenB) = deployer.run();

        vm.deal(user1, 1_000 ether);
        vm.deal(user2, 1_000 ether);
    }

    function testTradeWillRevertIfTokenNotApprove() public {
        vm.startPrank(deployerAddress);
        vm.expectRevert(abi.encodeWithSelector(TokenSwap.TokenSwap__AllowanceTooLow.selector, 0));
        tokenSwap.swap(addressTokenB, 10 ether);
        vm.stopPrank();
    }

    function testIfUserCanSwapTokenAFortokenB() public {
        uint256 amountToTrade = 10 ether;
        vm.startPrank(deployerAddress);
        ERC20Mock(addressTokenB).approve(address(tokenSwap), 1_000_000 ether);
        ERC20Mock(addressTokenA).approve(address(tokenSwap), 1_000_000 ether);
        ERC20Mock(addressTokenB).decimals();
        tokenSwap.swap(addressTokenB, amountToTrade);
        vm.stopPrank();
    }

    function testWillRevertIfNotSupportedToken() public {
        uint256 amountToTrade = 10 ether;
        vm.startPrank(deployerAddress);
        ERC20Mock(addressTokenB).approve(address(tokenSwap), 1_000_000 ether);
        ERC20Mock(addressTokenA).approve(address(tokenSwap), 1_000_000 ether);
        ERC20Mock(addressTokenB).decimals();
        vm.expectRevert(TokenSwap.TokenSwap__TokenAddressNotSwappable.selector);
        tokenSwap.swap(deployerAddress, amountToTrade);
        vm.stopPrank();
    }
}
