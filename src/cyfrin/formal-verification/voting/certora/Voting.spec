/*
    Voting Formal Verification
*/

methods {
    function vote(bool)external;
    function totalVotes() external returns uint256 envfree;
    function votesInFavor() external returns uint256 envfree;
    function votesAgainst() external returns uint256 envfree;
    function hasVoted(address voter) external returns bool envfree;
}

ghost mathint numVoted {
    init_state axiom numVoted == 0; 
}

ghost bool voteCasted;

ghost bool illegalVote {
    init_state axiom !illegalVote; 
}

hook Sstore _hasVoted[KEY address a] bool val (bool oldVal){
    // from false to true
    if(val && !oldVal){
        numVoted = numVoted +1;
    }
    // illegal: from false to false or false to false
    illegalVote = illegalVote || val;
    voteCasted = true;
}



invariant onlyLegalVotedChanges()
    !illegalVote;

invariant inFavorAndAgainstAreTotalVotes()
    votesInFavor() + votesAgainst() == totalVotes();

invariant numVotedIsTotalVotes()
    totalVotes() == numVoted;


rule voteOnOnlyCallingVote(method m){
    require !voteCasted;

    env e;
    calldataarg arg;
    m(e,arg);

    assert  voteCasted => m.selector == sig:vote(bool).selector, "Vote Casted with other than vote(bool)";
}

/* 
    @title: Votes in or against favor changes only by One
*/

rule inOrAgainstFavorChangesOnlyByOne(){
    uint256 againstBefore = votesAgainst();
    uint256 inFavorBefore = votesInFavor();

    //cast vote
    env e;
    bool inFavor;
    vote(e,inFavor);
    
    mathint againstDiff = votesAgainst() - againstBefore;
    mathint inFavorDiff = votesInFavor() - inFavorBefore;

    assert inFavorDiff >= 0 && inFavorDiff <= 1 , "votesInFavor did not change by 1 or 0";
    assert againstDiff >= 0 && againstDiff <= 1 , "votesAgainst did not change by 1 or 0";
}

/* 
    @title: Voter determines eiher inFavor or against
*/

rule votingDecides(){
    uint256 againstBefore = votesAgainst();
    uint256 inFavorBefore = votesInFavor();

    //cast vote
    env e;
    bool inFavor;
    vote(e,inFavor);

    assert (inFavor => votesInFavor() > inFavorBefore) && (!inFavor => votesAgainst() > againstBefore), "Voter's election did not apply"; 
}

/* 
    @title: anyone can vote unless overflow
*/

rule anyoneCanVote(address voter,bool inFavor){
    requireInvariant inFavorAndAgainstAreTotalVotes();

    env e;
    require e.msg.sender == voter;

    uint256 votesBefore = totalVotes();
    bool _hasVoted = hasVoted(voter);

    vote@withrevert(e, inFavor);

    assert  lastReverted <=> (_hasVoted || votesBefore == max_uint256 || e.msg.value > 0 ), "Can vote only once";
}