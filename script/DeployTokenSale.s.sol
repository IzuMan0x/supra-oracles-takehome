// SPDX-license-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {TokenSale} from "../src/TokenSale.sol";

/// @title Deploy script for TokenSale
/// @author IzuMan
/// @notice Deploys TokenSale
/// @dev Private key needs to be defined in the .env file (env file needs to be in the main folder of the Foundry project)

contract DeployTokenSale is Script {
    function run() public returns (TokenSale, address) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        //owner address
        address ownerAddress = vm.addr(deployerKey);
        //Token Address
        address tokenAddress;
        //address tokenAddress;
        //pre-sale
        uint256 preSaleMinTotalCap = 100 ether;
        uint256 preSaleMaxTotalCap = 1_000 ether;
        uint256 preSaleMinContribution = 1 ether;
        uint256 preSaleMaxContribution = 10 ether;
        //public-sale
        uint256 publicSaleMaxTotalCap = 1_000 ether;
        uint256 publicSaleMinTotalCap = 100 ether;
        uint256 publicSaleMinContribution = 1 ether;
        uint256 publicSaleMaxContribution = 10 ether;

        vm.startBroadcast(deployerKey);
        ERC20Mock erc20Mock = new ERC20Mock();
        tokenAddress = address(erc20Mock);
        TokenSale tokenSale = new TokenSale(
            ownerAddress,
            address(erc20Mock),
            //pre
            preSaleMinTotalCap,
            preSaleMaxTotalCap,
            preSaleMinContribution,
            preSaleMaxContribution,
            //public
            publicSaleMaxTotalCap,
            publicSaleMinTotalCap,
            publicSaleMinContribution,
            publicSaleMaxContribution
        );

        //Mint the token to the TokenSale address
        erc20Mock.mint(address(tokenSale), 10_000_000 ether);

        vm.stopBroadcast();
        return (tokenSale, tokenAddress);
    }
}
