// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {DecentralizedVotingSystem} from "../src/DecentralizedVotingSystem.sol";

contract DeployDecentralizedVotingSystem is Script {
    function run() public returns (DecentralizedVotingSystem) {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        DecentralizedVotingSystem decentralizedVotingSystem = new DecentralizedVotingSystem();

        vm.stopBroadcast();
        return (decentralizedVotingSystem);
    }
}
