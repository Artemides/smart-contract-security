/*
* Verification of Borda Election system
*/


methods {
    function points(address) external returns uint256 envfree;
    function vote(address,address,address) external;
    function voted(address) external returns bool envfree;
    function winner() external returns address  envfree;
}

/*
    Ingregrity of Winner
    The winner holds the highest points
    winner() = forAll c, points(c) <= points(w)
    Note: The prover checks the invariant is stablished after construction, and holds after any function execution
    Note: c is an unconstrained variable therefore this invariant is checked against all possible c values
*/

invariant integrityOfWinner(address c)
    points(winner()) >= points(c);
/*
*   After voting a user is marked as voted
*/
rule integrityVote(address f, address s, address t){
    env e;
    vote(e,f,s,t);
    assert voted(e.msg.sender), "a user voted without being marked accordingly";
}

/*
*   Users can only vote once
*/
rule singleVotes(address f, address s, address t){
    env e;
    bool hasVoted = voted(e.msg.sender);
    
    vote@withrevert(e,f,s,t);

    assert hasVoted => lastReverted, "double voting is not allowed";
}

rule integrityPoins(address f, address s, address t){
    env e;
    uint256 f_points = points(f);
    uint256 s_points = points(s);
    uint256 t_points = points(t);
    
    vote(e,f,s,t);
    
    assert to_mathint(points(f)) == f_points + 3 &&
           to_mathint(points(s)) == s_points + 2 &&
           to_mathint(points(t)) == t_points + 1, "unexpected change of points";

}

/*
*   Once a user votes it's marked as voted forever globally, cannot be changed ever
*/
rule foreverVoted(address x, method f){
    require voted(x);

    env e;
    calldataarg args;
    f(e,args); //run all functions along with all possible params

    assert voted(x), "user voted state was changed after voting";
}

/*
    Vote is the only state-changing function

*/

rule noEffect(method m) {
    address c;
    env e;
    uint256 c_points = points(c);
    bool c_voted = voted(c);
    
    if(m.selector == sig:vote(address,address,address).selector) {
        address f;
        address s;
        address t;

        require f != c && s != c && t != c ;

        vote(e, f, s, t);
    } else {
        calldataarg args;
        m(e,args);
    }

    assert (voted(c) == c_voted || c == e.msg.sender) && points(c) == c_points,"unexpected change of other points";
}

/*
    Order of votes don't matter
    Note: a hyperproterty as it compares results of different executions
*/

rule voteCommutativity(address f1,address s1,address t1,address f2,address s2,address t2){
    env e;
    env e2;
    address c;
    address y;
    
    storage init = lastStorage;
    vote(e,f1,s1,t1);
    vote(e2,f2,s2,t2);
    uint256 case1 = points(c);

    // reset storage
    vote(e2,f2,s2,t2) at init;
    vote(e,f1,s1,t1);
    uint256 case2 = points(c);

    assert case1 == case2, "vote() is not commutative";
    
}

/*
    Ability to vote
    if a user can vote, no other user cannot prevent him to do so by any operation unless max_uint reached
*/

rule allowVote(address f,address s,address t, method m){
    env e;
    storage init = lastStorage;
    vote(e, f, s, t);

    env e2;
    require (e.msg.sender != e2.msg.sender);
    calldataarg args;
    m(e2, args) at init;

    require points(f) < max_uint256 - 3  && points(s) < max_uint256 -2 && points(t) < max_uint256 - 1;

    vote@withrevert(e,f,s,t);

    assert !lastReverted, "a user cannot ve blocked from voting";
}
/*
    a user can vote unless ther's an overflow over points or it has already voted
*/
rule oneCanVote(address f, address s, address t) {
    env e;
    require e.msg.value == 0;
    bool overflowCheck = ( points(f) <= max_uint256 - 3  &&  points(s) <= max_uint256 - 2  &&  points(t) < max_uint256 );
    bool _voted = voted(e.msg.sender);

    vote@withrevert(e,f,s,t);

    bool reverted = lastReverted;

    assert (overflowCheck && !_voted && f!=s && s!=t && f!=t) <=> !reverted, "a user who hasn't voted yet should be able to do so unless overflow on candidate";
}

ghost mapping(address => uint256) points_mirror{
    init_state axiom forall address c. points_mirror[c] == 0;
}

ghost mathint countVoters{
    init_state axiom countVoters == 0;
}

ghost mathint sumPoints{
    init_state axiom sumPoints == 0;
}

hook Sstore _points[KEY address a] uint256 new_points (uint256 old_points){
    points_mirror[a] = new_points;
    sumPoints = sumPoints + new_points - old_points;
}

hook Sload uint256 curr_point _points[KEY address a] {
    require points_mirror[a] == curr_point;
}

hook Sstore _voted[KEY address a] bool val (bool old_value){
    countVoters = countVoters +1;
}
rule resolvabilityCriterion(address f, address s, address t, address tie){ 
    env e;
    address winnerBefore = winner();
    require (points(tie) == points(winner()));
    require forall address c. points_mirror[c] <= points_mirror[winnerBefore];
    vote(e, f, s, t);
    address winnerAfter = winner();
    satisfy forall address c. c != winnerAfter => points_mirror[c] < points_mirror[winnerAfter];
}   