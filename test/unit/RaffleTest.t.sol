//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

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

    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState()  == Raffle.RaffleState.OPEN);
    }

}