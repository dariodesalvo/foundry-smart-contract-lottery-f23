//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

//import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
 
 /**
  * @title A Sample Raffle Contract
  * @author Darío E. Desalvo
  * @notice This contract is for creating a sample raffle
  * @dev Implements Chainlink VRFv2
  */

contract Raffle is VRFConsumerBaseV2Plus, AutomationCompatibleInterface {
    
   error Raffle__NotEnoughEthSent();
   error Raffle__TransferFailed();
   error Raffle__NotOpen();
   error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

   event RequestFulfilled(uint256 requestId, uint256[] randomWords);

   /** Type Declarations */

   enum RaffleState {
      OPEN,
      CALCULATING
    }

   /** State variables  */

   //VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
   struct RequestStatus {
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
        uint256[] randomWords;
    }

   uint16 private constant REQUEST_CONFIRMATIONS = 3;
   uint32 private constant NUM_WORDS = 1;
   bool private constant ENABLE_NATIVE_PAYMENT = true;

   bytes32 private immutable i_keyHash;
   uint256 private immutable i_entranceFee;
   // @dev duration of the lottery in seconds
   uint256 private immutable i_interval;
   bytes32 private immutable i_gasLane;
   uint256 private immutable i_subscriptionId;
   uint32 private immutable i_callbackGasLimit;
   address payable[] private s_players;
   uint256 private s_lastTimeStamp;
   address private s_recentWinner;
   RaffleState private s_raffleState;

   /** Events */
   event RaffleEntered(address indexed player);
   event WinnerPicked(address indexed winner);
   event RequestRaffleWinner(uint256 indexed requestId);

   constructor(
      uint256 entranceFee,
      uint256 interval,
      bytes32 gasLane,
      uint256 subscriptionId,
      uint32 callbackGasLimit,
      address vrfCoordinatorV2_5,
      bytes32 keyHash
   )VRFConsumerBaseV2Plus(vrfCoordinatorV2_5){
   
      //i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
      i_entranceFee = entranceFee;
      i_interval = interval;
      i_gasLane = gasLane;
      i_subscriptionId = subscriptionId;
      i_callbackGasLimit = callbackGasLimit;
      i_keyHash = keyHash;
      s_raffleState = RaffleState.OPEN;
   }

   function enterRaffle()  external payable{
      if(msg.value < i_entranceFee){
         revert Raffle__NotEnoughEthSent();
      }
      if(s_raffleState != RaffleState.OPEN){
         revert Raffle__NotOpen();
      }
      s_players.push(payable(msg.sender));
      emit RaffleEntered(msg.sender);
   }

   /**
    * @dev This is the function that the Chainlink nodes will call to see
    * if the lottery is ready to have a winner picked.
    * The following should be true in order for upkeepNeeded to be true:
    * 1. The time interval has passed between raffle runs
    * 2. The lotery is OPEN
    * 3. The contract has ETH
    * 4. Implicitly, your suscription has LINK
    * @param - ignored 
    * @return upkeepNeeded - true if it's time to restart the lottery
    * @return - ignored
    */
   function checkUpkeep(
      bytes memory /* checkData */
    )
      public
      view
      returns (bool upkeepNeeded, bytes memory /* performData */)
    {
      bool timeHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval;
      bool isOpen = s_raffleState == RaffleState.OPEN;
      bool hasBalance = address(this).balance > 0;
      bool hasPlayers = s_players.length > 0;
      upkeepNeeded = timeHasPassed && isOpen && hasBalance && hasPlayers;
      return(upkeepNeeded, hex"");
    }


   function performUpkeep(bytes calldata /* performData */) external {
      (bool upkeepNeeded, ) = checkUpkeep("");
      if(!upkeepNeeded){
         revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
      }
      s_raffleState = RaffleState.CALCULATING;
      VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
            keyHash: i_keyHash,
            subId: i_subscriptionId,
            requestConfirmations: REQUEST_CONFIRMATIONS,
            callbackGasLimit: i_callbackGasLimit,
            numWords: NUM_WORDS,
            extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: ENABLE_NATIVE_PAYMENT}))
         });

      uint256 requestId = s_vrfCoordinator.requestRandomWords(request);
      emit RequestRaffleWinner(requestId);
       
   }

   function fulfillRandomWords(
      uint256 /* requestId */,
      uint256[] calldata randomWords
    ) internal override {
      //Checks
      //conditional

      //Effects
      uint256 indexOfWinner = randomWords[0] % s_players.length ;
      address payable recentWinner = s_players[indexOfWinner];
      s_recentWinner = recentWinner;
      s_raffleState = RaffleState.OPEN;
      s_players = new address payable[](0);
      s_lastTimeStamp = block.timestamp ;
      emit WinnerPicked(s_recentWinner);

      //Interactions
      (bool success, ) = recentWinner.call{value: address(this).balance}("");
      if (!success){
         revert();
      }
      
    } 

    /** Getter Function */

   function getEntranceFee() external view returns(uint256){
      return i_entranceFee;
   }

   function getRaffleState() external view returns(RaffleState){
      return s_raffleState;
   }
      
   function getPlayer(uint256 indexOfPlayer) external view returns(address){
      return s_players[indexOfPlayer];
   }
   
 }