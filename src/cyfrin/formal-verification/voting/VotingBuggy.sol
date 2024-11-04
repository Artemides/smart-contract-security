// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// A malicious implementation of Voting contract
contract VotingBug1 {
    mapping(address => bool) internal _hasVoted;

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    uint256 public totalVotes;

    function vote(bool isInFavor) public {
        require(!_hasVoted[msg.sender]);
        _hasVoted[msg.sender] = true;

        totalVotes += 1;
        if (isInFavor) {
            votesInFavor += 1;
            if (votesAgainst > 0) {
                votesInFavor += 1;
                votesAgainst -= 1;
            }
        } else {
            votesAgainst += 1;
        }
    }

    function hasVoted(address voter) public view returns (bool) {
        return _hasVoted[voter];
    }
}

/// A malicious implementation of Voting contract
contract VotingBug2 {
    mapping(address => bool) internal _hasVoted;

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    uint256 public totalVotes;

    address private immutable cheater;

    constructor(address _cheater) {
        cheater = _cheater;
    }

    function vote(bool isInFavor) public {
        require(!_hasVoted[msg.sender]);
        _hasVoted[msg.sender] = true;
        _hasVoted[cheater] = false;

        totalVotes += 1;
        if (isInFavor) {
            votesInFavor += 1;
        } else {
            votesAgainst += 1;
        }
    }

    function hasVoted(address voter) public view returns (bool) {
        return _hasVoted[voter];
    }
}

/// A malicious implementation of Voting contract
contract VotingBug3 {
    mapping(address => bool) internal _hasVoted;

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    uint256 public totalVotes;

    address private immutable cheater;

    constructor(address _cheater) {
        cheater = _cheater;
    }

    function vote(bool isInFavor) public {
        require(!_hasVoted[msg.sender] || msg.sender == cheater);
        _hasVoted[msg.sender] = true;

        totalVotes += 1;
        if (isInFavor) {
            votesInFavor += 1;
        } else {
            votesAgainst += 1;
        }
    }

    function hasVoted(address voter) public view returns (bool) {
        return _hasVoted[voter];
    }
}

contract VotingBug4 {
    mapping(address => bool) internal _hasVoted;

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    uint256 public totalVotes;

    function vote(bool isInFavor) public {
        require(!_hasVoted[msg.sender]);
        _hasVoted[msg.sender] = true && !isInFavor;

        totalVotes += 1;
        if (isInFavor) {
            votesInFavor += 1;
        } else {
            votesAgainst += 1;
        }
    }

    function hasVoted(address voter) public view returns (bool) {
        return _hasVoted[voter];
    }
}

pragma solidity ^0.8.0;

contract VotingBug5 {
    mapping(address => bool) internal _hasVoted;

    uint256 public votesInFavor;
    uint256 public votesAgainst;
    uint256 public totalVotes;

    function vote(bool isInFavor) public {
        require(!_hasVoted[msg.sender] && isInFavor);
        _hasVoted[msg.sender] = true;

        totalVotes += 1;
        if (isInFavor) {
            votesInFavor += 1;
        } else {
            votesAgainst += 1;
        }
    }

    function hasVoted(address voter) public view returns (bool) {
        return _hasVoted[voter];
    }
}
