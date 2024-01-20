// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {TokenSwap} from "../src/TokenSwap.sol";

contract DeployTokenSwap is Script {
    function run() public returns (TokenSwap, address, address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 exchangeRate = 2; //this is the exchange rate for tokenA to tokenB i.e. you can trade 1 of tokenA for tokenB

        vm.startBroadcast(deployerKey);

        //Create two ERC20 mock tokens to test the contract
        ERC20Mock tokenA = new ERC20Mock();
        ERC20Mock tokenB = new ERC20Mock();

        //Create and instance of the contract
        TokenSwap tokenSwap = new TokenSwap(address(tokenA), address(tokenB), exchangeRate);

        //Mint the contract some tokens so it can stay liquid
        tokenA.mint(address(tokenSwap), 10_000_000 ether);
        tokenB.mint(address(tokenSwap), 10_000_000 ether);

        //Mint some tokens for user to play around with
        tokenA.mint(address(vm.addr(deployerKey)), 500_000 ether);
        tokenB.mint(address(vm.addr(deployerKey)), 500_000 ether);

        vm.stopBroadcast();
        return (tokenSwap, address(tokenA), address(tokenB));
    }
}
