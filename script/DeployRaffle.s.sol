//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script {

    function run() public {}

    function deployContract() public returns(Raffle, HelperConfig){
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.gasLane,
            config.subscriptionId,
            config.callbackGasLimit,
            config.vrfCoordinatorV2_5,
            config. keyHash
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}