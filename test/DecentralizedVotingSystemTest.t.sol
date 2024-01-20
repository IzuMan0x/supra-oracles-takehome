// SPDX-LicenseIdentifier: UNLICENSED

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {DecentralizedVotingSystem} from "../src/DecentralizedVotingSystem.sol";
import {DeployDecentralizedVotingSystem} from "../script/DeployDecentralizedVotingSystem.s.sol";

contract DecentralizedVotingSystemTest is Test {
    DecentralizedVotingSystem public decentralizedVotingSystem;

    uint256 deployerKey = vm.envUint("PRIVATE_KEY");
    address deployerAddress = vm.addr(deployerKey);

    address candidate1 = makeAddr("candidate1");
    address candidate2 = makeAddr("candidate2");

    function setUp() public {
        address[] memory candidatesArray = new address[](3);
        candidatesArray[0] = deployerAddress;
        candidatesArray[1] = candidate1;
        candidatesArray[2] = candidate2;

        DeployDecentralizedVotingSystem deployer = new DeployDecentralizedVotingSystem();
        decentralizedVotingSystem = deployer.run();
        vm.startPrank(deployerAddress);
        decentralizedVotingSystem.openVotingRegistration(candidatesArray);
        vm.stopPrank();
    }

    function testIfSomeoneCanVote() public {
        //register to vote
        vm.startPrank(candidate1);
        decentralizedVotingSystem.registerToVote();
        vm.stopPrank();

        //use the owner account to open voting
        vm.startPrank(deployerAddress);
        decentralizedVotingSystem.openVoting();
        vm.stopPrank();

        //vote for candidate at index 1
        vm.startPrank(candidate1);
        decentralizedVotingSystem.vote(1);
        vm.stopPrank();
    }

    function testIfOnlyOwnerCanStartElection() public {
        vm.startPrank(candidate1);
        vm.expectRevert();
        decentralizedVotingSystem.openVoting();
        vm.stopPrank();
    }

    function testWillRevertIfVoterRegistersWhileRegistrationIsClosed() public {
        vm.startPrank(deployerAddress);
        decentralizedVotingSystem.closeVoterRegistration();
        vm.stopPrank();

        vm.startPrank(candidate1);
        vm.expectRevert(DecentralizedVotingSystem.DecentralizedVotingSystem__RegistrationNotOpen.selector);
        decentralizedVotingSystem.registerToVote();
        vm.stopPrank();
    }

    function testFullSucessfulCycleOfAnElection() public {
        //register to vote for candidate1
        vm.startPrank(candidate1);
        decentralizedVotingSystem.registerToVote();
        vm.stopPrank();
        //register to vote for candidate2
        vm.startPrank(candidate2);
        decentralizedVotingSystem.registerToVote();
        vm.stopPrank();

        //use the owner account to regitser for voting then open voting period
        vm.startPrank(deployerAddress);
        decentralizedVotingSystem.registerToVote();
        decentralizedVotingSystem.openVoting();
        vm.stopPrank();

        //vote for candidate at index 1 (which is candidate1 they are voting for themselves)
        vm.startPrank(candidate1);
        decentralizedVotingSystem.vote(1);
        vm.stopPrank();

        //candidate2 cast their vote
        vm.startPrank(candidate2);
        decentralizedVotingSystem.vote(1);
        vm.stopPrank();

        //deployerAddress votes and end the election
        vm.startPrank(deployerAddress);
        decentralizedVotingSystem.vote(1);
        decentralizedVotingSystem.closeVotingReturnWinner();
        vm.stopPrank();
    }
}
