<template>
  <div id="app">

  <H1 style="font-weight: bold; color:blueviolet; font-size: 70px; margin-bottom: 5%">REACH MORRA GAME</H1>

    <H3 style="font-weight: bold; font-size: 30px; margin-bottom: 2%">_(owo)_ Choose your player _(ovo)_</H3>
    <button @click="julia()" style="margin-right:2%; font-size: 25px; background-color: lightpink; padding-left:3%; padding-right:3%; color:mediumvioletred; border-radius: 25%">Julia</button> <a style="color:red; font-style:italic">VS</a>
    <button @click="finn()" style="margin-left:2.5%; font-size: 25px; background-color:aquamarine; padding-left:3%; padding-right:3%; color:green; border-radius: 25%; margin-bottom: 2%;">Finn</button>
    <BR/>
  
  <HR/>

  <div v-if="role==0" style="margin-top:2%">
  <h3 style="font-weight: bold; color:mediumvioletred">Julia</h3>

    <button @click="createContract()" style="margin-bottom:1.5%; background-color: red; color:white; font-size:20px" >Click to Deploy Contract</button><BR/>

    <a style="font-style:italic">contract: (Copy below to Finn)</a><BR/> 
    <h4 style="margin-top:0.5%">{{ ctcInfoStr }}</h4><BR /><BR />
  </div>

  <div v-else-if="role==1" style="margin-top:2%">
  <h3 style="font-weight: bold; color:green">Finn</h3>

  <input v-model="ctcStr" placeholder="paste contract here"> <button @click="attachContract()">Attach Contract</button>
  
    <BR/>  
    <div v-if="wager>0" style="margin-top:1.5%">
      Accept challenge of {{wager}} ? 
      <div style="margin-top:1.2%"><button @click="yesnoWager(true)" style="margin-right:1.5%; background-color: red; color:white; font-size:20px">YES</button>
      <button @click="yesnoWager(false)" style="font-size:20px">NO</button></div>
    </div>
    <BR/>     
  </div>

  <HR/>

    <div v-if="displayHandsState">
      <BR/>
      <h4>Last result are : </h4>
      <BR/>
      Julia hand: {{juliaHands}}
      Julia guess: {{juliaGuess}}
      <BR/>
      Finn hand: {{finnHands}}
      Finn guess: {{finnGuess}}
      <BR/>
  </div>

  <div v-if="getHandState" style="margin-top: 2%; font-weight: bold; font-size: 30px">
      Play your hand : <BR/>
      <button @click="readHand(0)" style="margin-top: 2%; margin-right:1%; margin-bottom:1%">0</button>
      <button @click="readHand(1)" style="margin-right: 1%">1</button>
      <button @click="readHand(2)">2</button> <BR/>
      <button @click="readHand(3)" style="margin-right: 1%">3</button> 
      <button @click="readHand(4)" style="margin-right: 1%">4</button> 
      <button @click="readHand(5)">5</button> 
      <BR/>
  </div>

  <div v-if="getGuessState" style="margin-top: 2%; font-weight: bold; font-size: 30px">
      Shout your total : <BR/>
      <button @click="readGuess(0)" style="margin-top: 2%; margin-right:1%; margin-bottom:1%"> 0 </button>
      <button @click="readGuess(1)" style="margin-right: 1%"> 1 </button>
      <button @click="readGuess(2)" style="margin-right: 1%"> 2 </button> 
      <button @click="readGuess(3)" style="margin-right: 1%"> 3 </button> 
      <button @click="readGuess(4)" style="margin-right: 1%"> 4 </button> 
      <button @click="readGuess(5)"> 5 </button> <BR/>
      <button @click="readGuess(6)" style="margin-right: 1%"> 6 </button> 
      <button @click="readGuess(7)" style="margin-right: 1%"> 7 </button> 
      <button @click="readGuess(8)" style="margin-right: 1%"> 8 </button> 
      <button @click="readGuess(9)" style="margin-right: 1%"> 9 </button> 
      <button @click="readGuess(10)"> 10 </button> 
      <BR/>
    </div>   

  <div v-if="displayResultState">
      <H3>{{resultString}}</H3>
  </div>
  
  <BR/>

  <HR/>
  addr: {{ addr}} <BR/>
  bal: {{ bal }} <BR/>
  balAtomic: {{ balAtomic }}<BR/>

  <button @click="updateBalance()" style="margin-top:1.5%">updateBalance</button>

  </div>
</template>

<script>
import * as backend from '../build/index.main.mjs';
import { loadStdlib } from '@reach-sh/stdlib';
//const stdlib = loadStdlib(process.env);

// Run in cmdline with 
// REACH_CONNECTOR_MODE=ALGO-Live
// ../reach devnet
const stdlib = loadStdlib("ALGO");
stdlib.setProviderByName("TestNet")

console.log(`The consensus network is ${stdlib.connector}.`);

//const suStr = stdlib.standardUnit;
//console.log("Unit is ", suStr)
//const toAU = (su) => stdlib.parseCurrency(su);
const toSU = (au) => stdlib.formatCurrency(au, 4);

// Defined all interact methods as global for backend calls, 
// later convert them to Vue methods
// These object MUST match the contract object in index.rsh

// This MUST match object in index.rsh
let gamerInteract = { };
let juliaInteract = { };
let finnInteract = { };

const OUTCOME = [ "NULL","Julia Wins", "Finn Wins" ];

// Setup secret seed here, loaded in .env.local
const secret = process.env.VUE_APP_SECRET1
const secret2 = process.env.VUE_APP_SECRET2

export default {
  name: 'App',
  components: {
  },
  data: () => {
    return {
      role: 0,
      acc: undefined,
      addr: undefined,
      balAtomic: undefined,
      bal: undefined,
      faucetLoading: false,
      ctc: undefined,
      ctcInfoStr: undefined,
      ctcStr: undefined,

      contractCreated: false,
      displayResultState: false,
      displayHandsState: false,
      getGuessState: false,
      getHandState: false,

      wager: undefined,
      hand: undefined,
      guess: undefined,
      juliaHands:undefined,
      juliaGuess:undefined,
      finnHands:undefined,
      finnGuess:undefined,
      resultString: undefined,
      acceptWager: undefined,
    };
  },
   methods: {

      // Create a Vue methods for every gamerInteract methods
      commonFunctions() {

        gamerInteract = {
            ...stdlib.hasRandom,
            reportResult: async (result) => { this.reportResult(result); },
            reportHands: (julia, juliaGuess, finn, finnGuess) => { this.reportHands(julia, juliaGuess, finn, finnGuess)},
            informTimeout: () => { this.informTimeout()},
            getHand: async () => {
                  console.log("*** getHand called from backend");
                  // this will use v-if to display the input
                  this.getHandState = true
                  // waitUtil hand is not undefined
                  await this.waitUntil(() => this.hand !== undefined );
                  console.log("You played ", this.hand + " finger(s)");
                  const hand = stdlib.parseCurrency(this.hand);
                  this.hand = undefined;
                  this.getHandState = false
                  return hand;
                },
            getGuess: async () => {
                  console.log("*** getGuess called from backend");
                  // this will use v-if to display the input
                  this.getGuessState = true
                  // waitUtil hand is not undefined
                  await this.waitUntil(() => this.guess !== undefined );
                  console.log("You guess total of ", this.guess);
                  const guess = stdlib.parseCurrency(this.guess);
                  this.guess = undefined;
                  this.getGuessState = false
                  return guess;
                },
          }
      },

      async reportResult(result) {
        // Return is 0x01 - Batman or 0x02 - Robin
        // How to convert to number ??
        console.log('*** reportResult ', result);
        this.resultString = OUTCOME[result];
        console.log('this.result ', this.resultString);
        // change state to true and display to web
        this.displayResultState = true;
        await this.updateBalance();
      },

      reportHands(julia, juliaGuess, finn, finnGuess) {
        console.log('*** The hands are ' + julia, juliaGuess, finn, finnGuess );
        this.juliaHands = toSU(julia);
        this.juliaGuess = toSU(juliaGuess);
        this.finnHands = toSU(finn);
        this.finnGuess = toSU(finnGuess);

        // change state to true and display to web
        this.displayHandsState = true;
      },

      readHand(hand) {
        console.log("readHand: ", hand)
        this.hand = hand;
      },

      readGuess(guess) {
        console.log("readguess: ", guess)
        this.guess = guess;
      },

    async createContract() {
          // create the contract here
          // https://docs.reach.sh/frontend/#ref-frontends-js-ctc
          console.log("Creating contract...")
          this.ctc = await this.acc.contract(backend);

          // The object must match backend in index.rsh
          this.ctc.p.Julia(juliaInteract);

          // This will be ran after the contract is deployed
          // the JSON contract will be displayed so others can attach this contract
          const info = await this.ctc.getInfo();
          this.ctcInfoStr = JSON.stringify(info);
          console.log("this.ctcInfoStr: ", this.ctcInfoStr);

          this.contractCreated = true;
          await this.updateBalance();
    },

    async julia() {
      this.commonFunctions();
      juliaInteract = {
            ...gamerInteract,
            wager: stdlib.parseCurrency(1),
            deadline: stdlib.parseCurrency(10),
        }

      console.log("Julia: ", juliaInteract);
      try {
          this.role = 0;
           // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
          // Get secret keywords from .env.local
          this.acc = await stdlib.newAccountFromMnemonic(secret);

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
            
      } catch (err) {
        console.log(err);
      }
    },
    
    //////////////////////////// Buyer

    async yesnoWager(res) {
        console.log("yesnoWager: ", res)
        this.acceptWager = res;
    },

   async attachContract() {
            this.ctc = await this.acc.contract(backend, JSON.parse(this.ctcStr));     
            console.log("Contract attached: ",this.ctcStr)
            await this.ctc.p.Finn(finnInteract);
            await this.updateBalance();
    },

    async finn() {
      this.commonFunctions();
      finnInteract = {
        ...gamerInteract,
         //acceptWager: Fun([UInt], Null),
          acceptWager: async (wager) => {
          console.log("*** acceptWager", wager);

          this.wager =  toSU(wager),
          this.waitUntil( ()=> this.acceptWager == true)
          // Exit if false
          if ( this.acceptWager == false) {
              process.exit(0);
          }
        }
      }
      console.log("Robin: ", finnInteract);

      try {
        // Set role, create account
          this.role = 1;
          // Change from devnet to testnet
          //this.acc = await stdlib.newTestAccount(stdlib.parseCurrency(1000));
          // Get secret keywords from .env.local
          this.acc = await stdlib.newAccountFromMnemonic(secret2);

          this.addr = stdlib.formatAddress(this.acc.getAddress());

          this.balAtomic = await stdlib.balanceOf(this.acc);
          this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));

      } catch (err) {
        console.log(err);
      }
    },  
    
    // Common function for all Vue Rech
    waitUntil (condition) {
    return new Promise((resolve) => {
        let interval = setInterval(() => {
            if (!condition()) {
                return
            }

            clearInterval(interval)
            resolve()
        }, 100)
      })
    },

    // Call this after every action to get current balance
    async updateBalance() {
      try {
        this.balAtomic = await stdlib.balanceOf(this.acc);
        this.bal = String(stdlib.formatCurrency(this.balAtomic, 4));
      } catch (err) {
        console.log(err);
      }
    },
  },
  computed: {
  },
  mounted() {
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
#wizard {
  width: 1024px;
}
.content {
  width: 1024px;
}
.navigation-buttons {
  display: flex;
  justify-content: space-between;
}
</style>
