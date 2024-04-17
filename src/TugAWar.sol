// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

uint256 constant startLine = 10;
uint256 constant hiLine = 15;
uint256 constant loLine = 5;

struct GameResult {
  address winner;
  address playerLight;
  address playerDark;
  uint256 firstBlock;
  uint256 lastBlock;
}

// TugAWar is a game that can only be played if you are a holder of a
// Downstream Zone 721 token
//
// This game is a bit light daily thompsons decathlon, but instead of smashing
// buttons you issue your transactions as fast as you can. If you can write
// a bot for this game you will win every game.
//
// The aim is to show that without changing the origin game (downstream), we can have
// players in that game interact with another using ERC 6551's Token Bound
// Accounts.
//
// It does require those players to use the command line and issue transactions for now.
//
// We think we can probably do ticket based escrow for Primordia using this but
// probably wont get that done today.
contract TugAWar {
    uint256 public nextGame;

    address playerLight;
    address playerDark;
    uint256 firstBlock;
    uint256 lastBlock;
    uint256 marker;

    GameResult currentGame;


    // maps winner address to the result
    GameResult []results;
    mapping(address => uint256) winners;

    constructor() {
      nextGame = 1;
      results.push();

      // alow games to start
      marker = startLine;
    }

    function getResult(uint256 i) public view returns (GameResult memory) {
      return results[i];
    }

    function joinTheLight() public {
      // TODO: require that msg.sender is a holder of a ds zone token ERC 6551
      if (playerLight != address(0)) revert("there can be only one");
      if (msg.sender == playerDark) revert("you need to find a friend");
      playerLight = msg.sender;
    }

    function joinTheDark() public {
      // TODO: require that msg.sender is a holder of a ds zone token using ERC 6551 
      if (playerDark != address(0)) revert("there can be only one");

      // because the account is bound to a specific token, the player would
      // have to PAY to mint two zones to pass this check. That is as much
      // sybil resitance as we can offer for now.
      if (msg.sender == playerLight) revert("you need to find a friend");
      playerDark = msg.sender;
    }

    // First one to the line wins, the light player heads to the light (up)
    function Add() public {

      // Because join required msg.sender to hold a ds zone token, this can
      // only be called by an address that is a holder of a zone token

      if (msg.sender != playerLight) revert("not in the light");
      if (playerDark == address(0)) revert("match not ready");

      // avoids weird states, shouldn't happen
      if (marker >= hiLine || marker <= loLine) revert("game over");

      marker += 1;
      if (marker == hiLine) {
        _declareWinner(msg.sender);
      }
    }

    // First one to the line wins, the dark player heads to the depths of hades (down)
    function Sub() public {

      // Because join required msg.sender to hold a ds zone token, this can
      // only be called by an address that is a holder of a zone token
      //
      if (msg.sender != playerDark) revert("not on the dark side");
      if (playerLight == address(0)) revert("match not ready");

      // avoids weird states, shouldn't happen
      if (marker >= hiLine || marker <= loLine) revert("game over");

      marker -= 1;
      if (marker != loLine) 
        return;
      _declareWinner(msg.sender);
    }

    function _declareWinner(address winner) internal {
      if (winner != playerLight && winner != playerDark) revert("invalid winner");

      uint256 i = results.length;
      results.push();

      results[i].winner = winner;
      results[i].playerLight = playerLight;
      results[i].playerDark = playerDark;

      // Let a new game start
      playerLight = address(0);
      playerDark = address(0);
      marker = startLine;
    }
}
