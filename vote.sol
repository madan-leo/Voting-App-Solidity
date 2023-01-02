//SPDX-License-Identifier: MJ
//-Solidity Code to handle a election voting scenario
//-Admin should be able to create and empty a poll before its locked
//-Admin should lock the poll before voting can happen
//-Voting records each address which votes
//-Admin can close the poll when the voting ends and a winner is stored
//-Winner call will show the winner
//Improvements: Check each address can vote only once
//Improvements: An address can delegate another address to vote on their behave
//Improvements: Resolve a tie after voting to declare multiple winners 
//Improvements: Make it more gas efficient

pragma solidity 0.8.17;
contract ElectionVoting{

    //Constructor to set creator as owner
    address public owner; 
    constructor(){
        owner = msg.sender;
    }

    //function to create a poll
    uint public totalPollsCount;
    mapping (bytes32 => pollDetails) public poll;
    struct pollDetails{
        bool isActive;
        bool isLocked;
        bool isClosed; 
	    bytes32 winner;
	    mapping(bytes32 => voteDetails) candidate;
        mapping(uint => bytes32) candidateIndex;
	    uint candidateCount;
    }
    struct voteDetails{
	    bool active;
        uint voteCount;
	    mapping (uint => address) voter;
    }

    //Admin function to create a new Poll
    function adminCreatePoll(bytes32 _poll) external{
        require(msg.sender == owner, "Only Owner can create a poll");
        require(poll[_poll].isActive == false, "Poll already exists");
        totalPollsCount++;
        poll[_poll].isActive=true;       
    }   

    //Admin function to add candidates to an existing poll
    function adminAddCandidates(bytes32 _poll, bytes32 _candidate) external{
        require(validPoll(_poll, true, false, false), "Invalid Poll criteria");
        require(poll[_poll].candidateCount<5, "More than 5 candidates not allowed");
        poll[_poll].candidateCount++;
        poll[_poll].candidateIndex[poll[_poll].candidateCount]=_candidate;
        poll[_poll].candidate[_candidate].active = true;   
    }   

    //Admin function to lock the poll. No more attributes like candidates,etc can be modified.
    function adminLockPoll(bytes32 _poll) external{
        require(validPoll(_poll, true, false, false), "Invalid Poll criteria");
        require(poll[_poll].candidateCount>1, "Not enough candidates to lock the voting");
        poll[_poll].isLocked = true;
    }   

    //function to clear candidates of a poll
    function adminEmptyCandidates(bytes32 _poll) external{   
        require(validPoll(_poll, true, false, false), "Invalid Poll criteria");   
        delete poll[_poll];
    }  

    //function to register a vote
    function vote(bytes32 _poll, bytes32 _option) external{
        require(validPoll(_poll, true, true, false), "Invalid Poll criteria");
        poll[_poll].candidate[_option].voteCount++;
        poll[_poll].candidate[_option].voter[poll[_poll].candidate[_option].voteCount] = msg.sender;
    }

    //Admin function to close the poll. Voting ends.
    function adminClosePoll(bytes32 _poll) external{
        uint j;
        uint i = poll[_poll].candidateCount;
        while(i>1) {
            if(poll[_poll].candidate[poll[_poll].candidateIndex[j]].voteCount < poll[_poll].candidate[poll[_poll].candidateIndex[i-1]].voteCount){
                j=i-1;          
            }
            i--;
        }
        poll[_poll].winner = poll[_poll].candidateIndex[j];
        poll[_poll].isClosed = true; 
    }

    //function to view votes for a candidate
    function viewVotes(bytes32 _poll, bytes32 _option) external view returns (uint){
        return(poll[_poll].candidate[_option].voteCount);
    }

    //function to view winner
    function viewWinner(bytes32 _poll) external view returns (bytes32){
        return(poll[_poll].winner);
    }

    //Internal function to check if a poll meets criteria
    function validPoll(bytes32 _poll, bool _isActive, bool _isLocked, bool _isClosed) private view returns(bool){
        require(poll[_poll].isActive == _isActive && poll[_poll].isLocked == _isLocked && poll[_poll].isClosed == _isClosed, "Invalid Poll criteria");
        return true;
    }

//Notes:
//public - all can access
//external - Cannot be accessed internally, only externally
//internal - only this contract and contracts deriving from it can access
//private - can be accessed only from this contract
}