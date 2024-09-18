// SPDX-License-Identifier: MIT
//Author:Kelvin Mulei 
pragma solidity ^0.8.0;

contract Voting {
    struct Proposal {
        address target;
        bytes data;
        uint yesCount;
        uint noCount;
        bool executed;
    }
    // Array
    Proposal[] public proposals;

    //introduce a constant for minimum number of yes votes to exe the proposal
    uint constant MIN_YES = 10;

    ///events
    event ProposalCreated(uint proposalID);
    event VoteCast(uint proposalID, address voter);
    event ProposalExecuted(uint proposalID);

    ///mapping for allowed adresses
    mapping(address => bool)public isAllowed;

    /// mapping to track voters vote for each proposal
   mapping(uint => mapping(address => bool)) public hasVoted;
   mapping(uint => mapping(address => bool)) public voteChoice;

   //Constructor
   constructor(address[] memory allowedAddresses){
       //add msg.sender to allowed list
       isAllowed[msg.sender] = true;

       //add all addresses in input array to allowed list
       for(uint i = 0; i < allowedAddresses.length; i++){
           isAllowed[allowedAddresses[i]] = true;
       } 
   }

   /// Access modifier 
   modifier onlyAllowed(){
       require(isAllowed[msg.sender], "Unauthorized!");
       _;
   }
    // function to create new proposals
    function newProposal(address _target, bytes calldata _data) external onlyAllowed{
        Proposal memory newProp = Proposal({
            target: _target,
            data: _data,
            yesCount: 0, //init as 0
            noCount: 0, //init as 0
            executed: false
        });
        
        //Add new proposal to proposals
        proposals.push(newProp);

        //emit event ProposalCreation
        emit ProposalCreated(proposals.length - 1);

    }

    //function to determine whether a vote supports a proposal
    function castVote(uint _propID, bool _supports) external onlyAllowed{
        //check if ID is valid
        require(_propID < proposals.length, "Invalid ID");

        //get the proposal by id
        Proposal storage proposal = proposals[_propID];

        // ensure proposal has been executed
        require(!proposal.executed, "Proposal already executed");
        // check if voter has voted
        if(hasVoted[_propID][msg.sender]){
            ///change vote 
            bool prevVote = voteChoice[_propID][msg.sender];

            if(prevVote && !_supports){
                //Yes to No
                proposal.yesCount -= 1;
                proposal.noCount += 1;
            }else if(!prevVote && _supports){
                //No to Yes
                proposal.noCount -= 1;
                proposal.yesCount += 1;

            }
        }else{
            // For first time voting
            if(_supports){
                proposal.yesCount += 1;
            }else{
                proposal.noCount += 1;
            }
            // Mark has voted
            hasVoted[_propID][msg.sender] = true;
        }

        //record voters choice
        voteChoice[_propID][msg.sender] = _supports;

        //emit VoteCast event
        emit VoteCast(_propID, msg.sender);

        //if more than ten has reached execute
        if(proposal.yesCount >= MIN_YES){
            executeProposal(_propID);
        }
    }
    // Function to execute the proposal once 10 yes votes are reached
    function executeProposal(uint _propID) internal {
        // Get the proposal by ID
        Proposal storage proposal = proposals[_propID];

        // Ensure the proposal has not been executed yet
        require(!proposal.executed, "Proposal already executed");

        // Execute the proposal by calling the target with the data
        (bool success, ) = proposal.target.call(proposal.data);
        require(success, "Proposal execution failed");

        // Mark the proposal as executed
        proposal.executed = true;

        // Emit ProposalExecuted event
        emit ProposalExecuted(_propID);
    }
}
