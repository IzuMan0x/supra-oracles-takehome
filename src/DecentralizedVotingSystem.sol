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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedVotingSystem
/// @author Marquis
/// @notice This is decentralized voting platform where address can register to vote then cast a vote for a certain candidate that is stored in an array
/// @dev Opening voter registration, adding candidates, and closing the election all have to be done manually by the owner which is by default is the address that deployed the contract
/// @dev It would be nice to add oracles and autmation into the smart contract

contract DecentralizedVotingSystem is Ownable {
    ////////////////////
    //  Errors ////////
    ////////////////////
    error DecentralizedVotingSystem__VoterAlreadyRegistered(address userAddress);
    error DecentralizedVotingSystem__AddressAlreadyVoted();
    error DecentralizedVotingSystem__AddressNotRegisteredToVote();
    error DecentralizedVotingSystem__CurrentVoteInProgress();
    error DecentralizedVotingSystem__RegistrationNotOpen();
    error DecentralizedVotingSystem__VotingNotOpen();
    error DecentralizedVotingSystem__VoterDataOldOrDidNotRegister();
    error DecentralizedVotingSystem__CannotAddCandidatesWhileVotingIsLive();
    error DecentralizedVotingSystem__AddressDidNotVoteInCurrentElection();

    ////////////////////
    // State Variables //
    ////////////////////
    struct Voter {
        bool registered;
        bool voted; // if true, that person already voted
        uint256 vote; //the index for who you voted for
        uint256 votingRound; // number indicating what round this data is for
    }

    //Struct for Candidates
    struct Candidate {
        address candidateAddress;
        uint256 voteCount; // number of accumulated votes
    }

    uint256 s_votingRound; //s_votingRound is incremented when a new election is started and it is used to check if voter data is fresh or from a past election

    address[] s_winners; //Array of address containing all the past winners for elections
    bool s_votingOpen; // bool if voting is open
    bool s_registrationOpen; // bool if registration is open

    //mapping of voter address to voter struct
    mapping(address => Voter) public s_voters;

    // A dynamically-sized array of candidate structs.
    Candidate[] public s_candidates;

    ////////////////////
    //  Events /////////
    ////////////////////
    event VoterRegistered(address indexed voterAddress);
    event UserVoted(address indexed voterAddress, address indexed candidateName);
    event ElectionWinner(uint256 indexed candidate, uint256 indexed voteCount, uint256 indexed votingRound);
    event VotingRegistrationOpenAndCandidatesAdded();
    event NewCandidateAdded(address indexed candidateAddress);
    event VoterRegistrationClosed(uint256 indexed electionNumber, uint256 time);
    event VotingOpened(uint256 indexed electionNumber, uint256 time);

    //////////////////////
    //  Functions ////////
    //////////////////////

    constructor() Ownable(msg.sender) {
        s_votingRound = 0;
    }

    /// @notice This allows the owner to open registratin and supply an array of candidates
    /// @param candidateAddresses is array of addresses for the condidates
    function openVotingRegistration(address[] memory candidateAddresses) external onlyOwner {
        delete s_candidates;
        s_votingRound++;
        if (s_votingOpen == true) {
            revert DecentralizedVotingSystem__CurrentVoteInProgress();
        }

        for (uint256 i = 0; i < candidateAddresses.length; i++) {
            s_candidates.push(Candidate({candidateAddress: candidateAddresses[i], voteCount: 0}));
        }
        s_registrationOpen = true;
        emit VotingRegistrationOpenAndCandidatesAdded();
    }

    /// @notice Allows the owner of the contract to close voter registration
    function closeVoterRegistration() external onlyOwner {
        s_registrationOpen = false;
        emit VoterRegistrationClosed(s_votingRound, block.timestamp);
    }

    function openVoting() external onlyOwner {
        s_votingOpen = true;
        emit VotingOpened(s_votingRound, block.timestamp);
    }

    function addCandidate(address candidateAddress) external onlyOwner {
        if (s_votingOpen == true) {
            revert DecentralizedVotingSystem__CannotAddCandidatesWhileVotingIsLive();
        } else {
            Candidate memory candidate = Candidate({candidateAddress: candidateAddress, voteCount: 0});
            s_candidates.push(candidate);
        }
        emit NewCandidateAdded(candidateAddress);
    }

    /// @notice This allows a user to register to vote
    function registerToVote() external {
        if (s_voters[msg.sender].registered == true) {
            revert DecentralizedVotingSystem__VoterAlreadyRegistered(msg.sender);
        } else if (s_registrationOpen != true) {
            revert DecentralizedVotingSystem__RegistrationNotOpen();
        } else {
            s_voters[msg.sender].registered = true;
            s_voters[msg.sender].votingRound = s_votingRound;
            emit VoterRegistered(msg.sender);
        }
    }

    /// @notice User can vote with the index of the canidate in the candidate array
    /// @dev Address must have registered to vote previously and not already voted
    function vote(uint256 candidate) external {
        if (s_votingOpen != true) {
            revert DecentralizedVotingSystem__VotingNotOpen();
        } else if (s_voters[msg.sender].votingRound != s_votingRound) {
            revert DecentralizedVotingSystem__VoterDataOldOrDidNotRegister();
        }

        if (s_voters[msg.sender].voted == true) {
            revert DecentralizedVotingSystem__AddressAlreadyVoted();
        } else if (s_voters[msg.sender].registered != true) {
            revert DecentralizedVotingSystem__AddressNotRegisteredToVote();
        } else {
            s_voters[msg.sender].voted = true;
            s_voters[msg.sender].votingRound = s_votingRound;

            s_voters[msg.sender].vote = candidate;
            //If the condidate does not exist in the error the call will automatically revert
            s_candidates[candidate].voteCount++;
            emit UserVoted(msg.sender, s_candidates[candidate].candidateAddress);
        }
    }

    /// @dev Computes the winning proposal taking all
    /// previous votes into account.
    // @dev this function will still return a winner if there are no votes and it will be the first candidate in the array
    function closeVotingReturnWinner() external onlyOwner returns (uint256, uint256, uint256) {
        s_votingOpen = false;

        uint256 winningVoteCount = 0;

        uint256 winningCandidate;
        for (uint256 c = 0; c < s_candidates.length; c++) {
            if (s_candidates[c].voteCount > winningVoteCount) {
                winningVoteCount = s_candidates[c].voteCount;
                winningCandidate = c;
            }
        }

        s_winners.push(s_candidates[winningCandidate].candidateAddress);

        emit ElectionWinner(winningCandidate, winningVoteCount, s_votingRound);

        return (winningCandidate, winningVoteCount, s_votingRound);
    }

    /// @notice this will the candidate array with the current results
    /// @dev If there is not a live election it will show the candidated of the previous election
    function getCurrentElectionResults() external view returns (Candidate[] memory) {
        return s_candidates;
    }

    /// @notice Returns the current voting round
    function getCurrentVotingRound() external view returns (uint256) {
        return s_votingRound;
    }

    /// @notice Gets a user voter data for current or past election if there is no live election
    function getUserVoterData() external view returns (address, uint256) {
        if (s_votingRound != s_voters[msg.sender].votingRound && s_voters[msg.sender].voted == true) {
            revert DecentralizedVotingSystem__AddressDidNotVoteInCurrentElection();
        } else {
            uint256 candidateIndex = s_voters[msg.sender].vote;
            return (s_candidates[candidateIndex].candidateAddress, candidateIndex);
        }
    }
}
