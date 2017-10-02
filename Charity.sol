pragma solidity ^0.4.2;

contract Charity {

    uint public debatingPeriodInMinutes;
    Proposal[] public proposals;
    uint public numProposals;
    uint public numMembers;
    mapping (address => uint) public memberId;
    address[] public members;

    struct Proposal {
        address recipient;
        uint amount;
        string description;
        uint votingDeadline;
        bool executed;
        bool proposalPassed;
        uint numberOfVotes;
        int currentResult;
        Vote[] votes;
        mapping (address => bool) voted;
    }

    struct Vote {
        bool inSupport;
        address voter;
    }

    /* modifier that allows only shareholders to vote and create new proposals */
    modifier onlyMembers {
        require (memberId[msg.sender] != 0);
        _;
    }

    /* First time setup */
    function Charity( uint _minutesForDebate ) payable {
        debatingPeriodInMinutes = _minutesForDebate;
        members.length++;
    }

    function isMember( address _targetMember ) constant returns ( bool ) {
        return ( memberId[_targetMember] != 0 );
    }

    function addMember( address _targetMember ) {
        if ( !isMember(_targetMember) ) {
           uint id;
           memberId[_targetMember] = members.length;
           id = members.length++;
           numMembers = members.length - 1;
           members[id] = _targetMember;
        }
    }


    function newProposal(
        address _beneficiary,
        uint _weiAmount,
        string _description
    )
        onlyMembers
        returns (uint proposalID)
    {
        require( _weiAmount <= (1 ether) );
        proposalID = proposals.length++;
        Proposal storage p = proposals[proposalID];
        p.recipient = _beneficiary;
        p.amount = _weiAmount;
        p.description = _description;
        p.votingDeadline = now + debatingPeriodInMinutes * 1 minutes;
        p.executed = false;
        p.proposalPassed = false;
        p.numberOfVotes = 0;
        numProposals = proposalID + 1;

        return proposalID;
    }

    function getProposal( address _member, uint _proposalNumber ) constant
        returns ( address,
                  uint,
                  string,
                  uint,
                  bool,
                  bool,
                  uint,
                  int,
                  int ) {
        Proposal memory proposal = proposals[ _proposalNumber ];
        int vote = getVoted( _member, _proposalNumber );
        return ( proposal.recipient,
                 proposal.amount,
                 proposal.description,
                 proposal.votingDeadline,
                 proposal.executed,
                 proposal.proposalPassed,
                 proposal.numberOfVotes,
                 proposal.currentResult,
                 vote );
    } 

    function vote(
        uint _proposalNumber,
        bool _supportsProposal
    )
        onlyMembers
        returns (uint voteID)
    {
        Proposal storage p = proposals[_proposalNumber];        // Get the proposal
        require (p.voted[msg.sender] != true);          // If has already voted, cancel
        p.voted[msg.sender] = true;                     // Set this voter as having voted
        p.numberOfVotes++;                              // Increase the number of votes
        if (_supportsProposal) {                        // If they support the proposal
            p.currentResult++;                          // Increase score
        } else {                                        // If they don't
            p.currentResult--;                          // Decrease the score
        }
        voteID = p.votes.length++;
        p.votes[voteID] = Vote({inSupport: _supportsProposal, voter: msg.sender});
        return p.numberOfVotes;
    }

    function getVoted(address _member, uint _proposalNumber) constant returns(int)
    {
      Proposal storage p = proposals[_proposalNumber];
      int result = 0;
      int true_int = 1;
      int false_int = -1;
      for (uint i = 0; i < p.numberOfVotes; i++)
      {
        if (p.votes[i].voter == _member)
        {
          result = p.votes[i].inSupport ? true_int : false_int;
          break;
        }
      }
      return result;
    }

    function executeProposal(uint _proposalNumber) {
        Proposal storage p = proposals[_proposalNumber];

        require ( !(now < p.votingDeadline || p.executed) );

        p.executed = true;

        if (p.currentResult > 0) {
            require ( p.recipient.send(p.amount) );
            p.proposalPassed = true;
        } else {
            p.proposalPassed = false;
        }
    }

    function () payable {}
}
