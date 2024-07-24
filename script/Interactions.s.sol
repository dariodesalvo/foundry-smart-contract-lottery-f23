//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "./HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {

    function createSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        address account = helperConfig.getConfig().account;
        (uint256 subId,) = createSubscription(vrfCoordinatorV2_5, account);
        return (subId, vrfCoordinatorV2_5);
    }

    function createSubscription(address vrfCoordinatorV2_5, address account) public returns(uint256, address) {
        console.log("Creating subscription on chain Id: ", block.chainid);
        vm.startBroadcast(account);
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).createSubscription();
        vm.stopBroadcast();

        console.log("Your subscription Id is: ", subId);
        console.log("Please update the subscriptionId in your HelperConfig.s.sol");
        return (subId, vrfCoordinatorV2_5);
    }

    function run() public {
        createSubscriptionUsingConfig();
    }
}

contract FundSubscription is Script, CodeConstants {

    uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address link = helperConfig.getConfig().link;
        address account = helperConfig.getConfig().account;
        fundSubscription(vrfCoordinatorV2_5, subscriptionId, link, account);
    }

    function fundSubscription(address vrfCoordinatorV2_5, uint256 subscriptionId, address linkToken, address account) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("Using vrfCoordinatorV2_5: ",vrfCoordinatorV2_5);
        console.log("on ChainId: ",block.chainid);

        if(block.chainid == LOCAL_CHAIN_ID){
            vm.startBroadcast();
            VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).fundSubscription(subscriptionId, FUND_AMOUNT * 100);
            vm.stopBroadcast();    
        }else{
            vm.startBroadcast(account);
            LinkToken(linkToken).transferAndCall(vrfCoordinatorV2_5, FUND_AMOUNT, abi.encode(
                subscriptionId));
            vm.stopBroadcast();
        }

    }

    function run() public {
        fundSubscriptionUsingConfig();
    }

}

contract AddConsumer is Script {

    function  addConsumerUsingConfig(address mostRecentlyDeploy) public {
        HelperConfig helperConfig = new HelperConfig();
        address vrfCoordinatorV2_5 = helperConfig.getConfig().vrfCoordinatorV2_5;
        uint256 subscriptionId = helperConfig.getConfig().subscriptionId;
        address account = helperConfig.getConfig().account;
        addConsumer(mostRecentlyDeploy, vrfCoordinatorV2_5,subscriptionId, account);
    }

    function addConsumer(address contractToAddToVrf, address vrfCoordinatorV2_5, uint256 subscriptionId, address account) public {
        console.log("Adding consumer contract: ", contractToAddToVrf);
        console.log("Using vrfCoordinator: ", vrfCoordinatorV2_5);
        console.log("On ChainID: ", block.chainid);
        vm.startBroadcast(account);
        VRFCoordinatorV2_5Mock(vrfCoordinatorV2_5).addConsumer(subscriptionId, contractToAddToVrf);
        vm.stopBroadcast();
    }
    
    
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
        addConsumerUsingConfig(mostRecentlyDeployed);
    }
}