pragma solidity ^0.4.15;

contract Betting {
	/* Standard state variables */
	address public owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;	// Feel free to replace with a mapping

	bool betOpen = false;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();
	event OwnerSet(address ownerAddr);
	event OracleSet(address oracleAddr);
	event DecisionMade(address oracleAddr, uint decision);

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		if (msg.sender == owner) {
			_;
		}
	}
	modifier OracleOnly() {
		if (msg.sender == oracle) {
			_;
		}
	}
	modifier NotOwnerOrOracle() {
		if (msg.sender != owner && msg.sender != oracle) {
			_;
		}
	}
	modifier CanMakeNewBet() {
		if (betOpen == false) {
			_;
		}
	}

	/* Constructor function, where owner and outcomes are set */
	function Betting(uint[] _outcomes) CanMakeNewBet() {
		owner = msg.sender;
		outcomes = _outcomes;
		betOpen = true;
		OwnerSet(owner);
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		oracle = _oracle;
		OracleSet(oracle);
		return oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) NotOwnerOrOracle() payable returns (bool) {
		if (gamblerA == address(0)) {
			gamblerA = msg.sender;
		}
		else if (gamblerB == address(0) && gamblerA != msg.sender) {
			gamblerB = msg.sender;
		}
		else {
			return false;
		}

		bets[msg.sender] = Bet({
			outcome: _outcome,
			amount: msg.value,
			initialized: true
			});

		BetMade(msg.sender);

		return true;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		if (bets[gamblerA].outcome == bets[gamblerB].outcome) {
			winnings[gamblerA] = bets[gamblerA].amount;
			winnings[gamblerB] = bets[gamblerB].amount;
		}
		else if (bets[gamblerA].outcome == _outcome) {
			winnings[gamblerA] = bets[gamblerA].amount + bets[gamblerB].amount;
		}
		else if (bets[gamblerB].outcome == _outcome) {
			winnings[gamblerB] = bets[gamblerA].amount + bets[gamblerB].amount;
		}
		else {
			winnings[oracle] = bets[gamblerA].amount + bets[gamblerB].amount;
		}

		BetClosed();
		contractReset();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		if (withdrawAmount > winnings[msg.sender]) {
			return winnings[msg.sender];
		}

		winnings[msg.sender] -= withdrawAmount;
		msg.sender.transfer(withdrawAmount);
		return winnings[msg.sender];
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete bets[gamblerA];
		delete bets[gamblerB];

		owner = address(0);
		gamblerA = address(0);
		gamblerB = address(0);
		oracle = address(0);

		betOpen = false;
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
