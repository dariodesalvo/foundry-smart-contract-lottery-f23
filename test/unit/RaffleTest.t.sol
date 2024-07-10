//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";

contract RaffleTest is Test {

    
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    Raffle public raffle;
    HelperConfig public helperConfig;

    address public PLAYER = makeAddr("player");

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinatorV2_5;
    bytes32 gasLane;
    uint256 subscriptionId;
    uint32 callbackGasLimit;  
    bytes32 keyHash; 

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    function setUp() external {
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval  = config.interval;
        vrfCoordinatorV2_5 = config.vrfCoordinatorV2_5;
        gasLane = config.gasLane;
        subscriptionId = config.subscriptionId;
        callbackGasLimit = config.callbackGasLimit;
        keyHash = config.keyHash;
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState()  == Raffle.RaffleState.OPEN);
    }

    function testRaffleRevertWhenYouDontPayEnough() public {
        //Arrange
        vm.prank(PLAYER);
        //Act /Asset
        vm.expectRevert(Raffle.Raffle__NotEnoughEthSent.selector);
        raffle.enterRaffle();
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        //Arrange
        vm.prank(PLAYER);
        //Act 
        raffle.enterRaffle{value:entranceFee}();
        //Asset
        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
        
    }

    function testEnteringRaffleEmitsEvent() public {
        //Arrange
        vm.prank(PLAYER);
        //Act
        vm.expectEmit(true,false,false,false, address(raffle));
        emit RaffleEntered(PLAYER);
        //Asset
        raffle.enterRaffle{value:entranceFee}();
    }

    modifier raffleEntered() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number+1);
        _;
    }

    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public raffleEntered {
        //Arrange
        raffle.performUpkeep("");

        //Act
        //Asset
        vm.expectRevert(Raffle.Raffle__NotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        //Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number+1);
        
        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);
    }

    function testCheckUpKeepReturnsFalseIfRaffleIsntOpen() public raffleEntered {

         //Arrange
        raffle.performUpkeep("");  

        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded);    

    }

    // challenge 

    function testCheckUpKeepReturnsFalseIfEnoughtTimeHasPassed() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(!upKeepNeeded); 
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public raffleEntered {
        
        //Act
        (bool upKeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upKeepNeeded);
    }

    /* Perform Upkeep */

    function testPerformUpkeepCanOnlyRunIfCheckUpKeepIsTrue() public raffleEntered {

        //Arrange  

        //Act / Assert       
        raffle.performUpkeep("");      
   
    }

    function testPerformUpkeepRevertIfCheckUpKeepIsFalse() public {

        //Arrange  
        uint256 currentBalance = 0;
        uint256 numPlayers = 0;
        Raffle.RaffleState rState  = raffle.getRaffleState();
        vm.prank(PLAYER);  
        raffle.enterRaffle{value: entranceFee}();
        currentBalance += entranceFee;
        numPlayers += 1;

        //Act / Assert       
        vm.expectRevert(
            abi.encodeWithSelector(Raffle.Raffle__UpkeepNotNeeded.selector, currentBalance,
            numPlayers, rState)
            );  
        raffle.performUpkeep(""); 
    }

    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
    
        //Arrange

        //Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[]memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState rState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    
    }
}