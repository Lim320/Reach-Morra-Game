'reach 0.1';

// create enum for first 5 fingers
//const [ isHand, ZERO, ONE, TWO, THREE, FOUR, FIVE ] = makeEnum(6);

// create enum for results
const [ isResult, NO_WINS, A_WINS, B_WINS, DRAW,  ] = makeEnum(4);

// 0 = none, 1 = B wins, 2 = draw , 3 = A wins
const winner = (handJulia, guessJulia, handFinn, guessFinn) => {
  const total = handJulia + handFinn;

  if ( guessJulia == total && guessFinn == total  ) {
      // draw
      return DRAW
  }  else if ( guessFinn == total) {
      // Finn wins
      return B_WINS
  }
  else if ( guessJulia == total ) { 
      // Julia wins
      return A_WINS
  } else {
    // else no one wins
      return NO_WINS
  }
 
}
  
assert(winner(1,2,1,3 ) == A_WINS);
assert(winner(5,10,5,8 ) == A_WINS);

assert(winner(3,6,4,7 ) == B_WINS);
assert(winner(1,5,3,4 ) == B_WINS);

assert(winner(0,0,0,0 ) == DRAW);
assert(winner(2,4,2,4 ) == DRAW);
assert(winner(5,10,5,10 ) == DRAW);

assert(winner(3,6,2,4 ) == NO_WINS);
assert(winner(0,3,1,5 ) == NO_WINS);

forall(UInt, handJulia =>
  forall(UInt, handFinn =>
    forall(UInt, guessJulia =>
      forall(UInt, guessFinn =>
    assert(isResult(winner(handJulia, guessJulia, handFinn , guessFinn)))
))));


// Setup common functions
const gamerInteract = {
  ...hasRandom,
  reportResult: Fun([UInt], Null),
  reportHands: Fun([UInt, UInt, UInt, UInt], Null),
  informTimeout: Fun([], Null),
  getHand: Fun([], UInt),
  getGuess: Fun([], UInt),
};

const juliaInterect = {
  ...gamerInteract,
  wager: UInt, 
  deadline: UInt, 
}

const finnInteract = {
  ...gamerInteract,
  acceptWager: Fun([UInt], Null),
}


export const main = Reach.App(() => {
  const Julia = Participant('Julia',juliaInterect );
  const Finn = Participant('Finn', finnInteract );
  init();

  // Check for timeouts
  const informTimeout = () => {
    each([Julia, Finn], () => {
      interact.informTimeout();
    });
  };

  Julia.only(() => {
    const wager = declassify(interact.wager);
    const deadline = declassify(interact.deadline);
  });
  Julia.publish(wager, deadline)
    .pay(wager);
  commit();

  Finn.only(() => {
    interact.acceptWager(wager);
  });
  Finn.pay(wager)
    .timeout(relativeTime(deadline), () => closeTo(Julia, informTimeout));
  

  var result = DRAW;
   invariant( balance() == 2 * wager && isResult(result) );

   ///////////////// While DRAW or NO_WINS //////////////////////////////
   while ( result == DRAW || result == NO_WINS ) {
    commit();

  Julia.only(() => {
    const _handJulia = interact.getHand();
    const [_commitJulia1, _saltJulia1] = makeCommitment(interact, _handJulia);
    const commitJulia1 = declassify(_commitJulia1);

    const _guessJulia = interact.getGuess();
    const [_commitJulia2, _saltJulia2] = makeCommitment(interact, _guessJulia);
    const commitJulia2 = declassify(_commitJulia2);

  })
  

  Julia.publish(commitJulia1, commitJulia2)
      .timeout(relativeTime(deadline), () => closeTo(Finn, informTimeout));
    commit();

  // Finn must NOT know about Batman hand and guess
  unknowable(Finn, Julia(_handJulia,_guessJulia, _saltJulia1,_saltJulia2 ));
  
  // Get Finn hand
  Finn.only(() => {
    const handFinn = declassify(interact.getHand());
    const guessFinn = declassify(interact.getGuess());
  });

  Finn.publish(handFinn, guessFinn)
    .timeout(relativeTime(deadline), () => closeTo(Julia, informTimeout));
  commit();

  Julia.only(() => {
    const saltJulia1 = declassify(_saltJulia1);
    const handJulia = declassify(_handJulia);
    const saltJulia2 = declassify(_saltJulia2);
    const guessJulia = declassify(_guessJulia);

  });

  Julia.publish(saltJulia1,saltJulia2, handJulia, guessJulia)
    .timeout(relativeTime(deadline), () => closeTo(Finn, informTimeout));
  checkCommitment(commitJulia1, saltJulia1, handJulia);
  checkCommitment(commitJulia2, saltJulia2, guessJulia);

  // Report results to all participants
  each([Julia, Finn], () => {
    interact.reportHands(handJulia, guessJulia, handFinn, guessFinn);
  });

  result = winner(handJulia, guessJulia, handFinn, guessFinn);
  continue;
}
// check to make sure no DRAW or NO_WINS
assert(result == A_WINS || result == B_WINS);

each([Julia, Finn], () => {
  interact.reportResult(result);
});

transfer(2 * wager).to(result == A_WINS ? Julia : Finn);
commit();

});
