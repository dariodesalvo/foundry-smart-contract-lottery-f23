//SPDX-License-Identifier: MIT

 pragma solidity ^0.8.18;

 /**
  * @title A Sample Raffle Contract
  * @author Darío E. Desalvo
  * @notice This contract is for creating a sample raffle
  * @dev Implements Chainlink VRFv2
  */

 contract Raffle {
    
   error Raffle__NotEnoughEthSent();
   uint256 private immutable i_entranceFee;
   address payable[] private s_players;

   /** Events */
   event RaffleEntered(address indexed player);

   constructor(uint256 entranceFee){
      i_entranceFee = entranceFee;
   }

   function enterRaffle()  external payable{
      if(msg.value < i_entranceFee){
         revert Raffle__NotEnoughEthSent();
      }
      s_players.push(payable(msg.sender));
      emit RaffleEntered(msg.sender);
   }

   function pickWinner() public {}

    /** Getter Function */

   function getEntranceFee() external view returns(uint256){
      return i_entranceFee;
   }
 }