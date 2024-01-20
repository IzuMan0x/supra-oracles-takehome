// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract DeployMultiSigWallet is Script {
    function run() public returns (MultiSigWallet, uint256, uint256, uint256) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 account1 = vm.envUint("ACCOUNT1");
        uint256 account2 = vm.envUint("ACCOUNT2");
        uint256 amountOfConfirmationsNeeded = 2;

        //address[3] memory ownersAddress = [vm.addr(deployerKey), vm.addr(account1), vm.addr(account2)];
        address[] memory ownersAddress = new address[](3);
        ownersAddress[0] = vm.addr(deployerKey);
        ownersAddress[1] = vm.addr(account1);
        ownersAddress[2] = vm.addr(account2);

        vm.startBroadcast(deployerKey);

        MultiSigWallet multiSigWallet = new MultiSigWallet(ownersAddress, amountOfConfirmationsNeeded);

        vm.stopBroadcast();
        return (multiSigWallet, deployerKey, account1, account2);
    }
}
