import { loadStdlib, ask } from '@reach-sh/stdlib';
import * as backend from './build/index.main.mjs';
const stdlib = loadStdlib();

const suStr = stdlib.standardUnit; 
// The standard unit is ALGO, we deal with this unit
// The atomic unit is μALGO, blockchain delas with this unit
const toAU = (su) => stdlib.parseCurrency(su);
const toSU = (au) => stdlib.formatCurrency(au, 4);
const iBalance = toAU(1000);
const showBalance = async (acc) => console.log(`Your balance is ${toSU(await stdlib.balanceOf(acc))} ${suStr}.`);

const OUTCOME = ['NO_WINS', 'Julia WINS', 'Finn WINS', 'DRAW', ];

const gamerInteract = {
  ...stdlib.hasRandom,
  reportResult:  (result) => { console.log(`The result is: ${OUTCOME[result]}`)},
  //interact.reportHands(handJulia, guessJulia, handFinn, guessFinn, total );

  reportHands:  (A,aGuess,B, bGuess) => { 
    console.log(`*** Julia played hand: ${toSU(A)}, guess: ${toSU(aGuess)} `)
    console.log(`*** Finn played hand: ${toSU(B)}, guess: ${toSU(bGuess)} `)
    console.log(`*** Total fingers : ${toSU( parseInt(A)+parseInt(B) )}`)
  },
  informTimeout: () => {  console.log(`There was a timeout.`); 
                            process.exit(1);
                          },
  //getHand: Fun([], UInt),
  getHand: async () => {  
          const hand = await ask.ask( `How many fingers?`, stdlib.parseCurrency );
          return hand
                        },
  //getGuess: Fun([], UInt),
  getGuess: async () => {
        const guess = await ask.ask( `Guess total fingers?`, stdlib.parseCurrency );
        return guess
  },

}


const isJulia = await ask.ask(
  `Are you Julia?`,
  ask.yesno
);
const who = isJulia ? 'Julia' : 'Finn';

console.log(`Starting MORRA as ${who}`);

let acc = null;

if (who === 'Julia') {
  const amt = await ask.ask( `How much do you want to wager?`, stdlib.parseCurrency );

  const juliaInteract = {
  ...gamerInteract,
  wager: amt,
  deadline:100,
  }

  // create new test account with 1000 ALGO
  const acc = await stdlib.newTestAccount(iBalance);
  await showBalance(acc);

  // First participant, deploy the contract
  const ctc = acc.contract(backend);
  
  ctc.getInfo().then((info) => {
    console.log(`The contract is deployed as = ${JSON.stringify(info)}`); });

  await ctc.p.Julia(juliaInteract);
  await showBalance(acc);
  
} else if ( who === 'Finn') {
  const finnInteract = {
    ...gamerInteract,
    acceptWager: async (amt) => {
      const accepted = await ask.ask( `Do you want to accept water of ${toSU(amt)} ?`, ask.yesno )
        if (!accepted) {
          process.exit(0);
        }
      }
  }

  const acc = await stdlib.newTestAccount(iBalance);
  const info = await ask.ask('Paste contract info:', (s) => JSON.parse(s));

  // Other participants, attached the contract from seller
  const ctc = acc.contract(backend, info);
  await showBalance(acc);

  // finn interaction
  await ctc.p.Finn(finnInteract);
  await showBalance(acc);

} 

ask.done();
