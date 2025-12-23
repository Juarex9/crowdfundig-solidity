// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

contract CrowFunding {
    enum Status { Active, Successful, Failed} //Enumera en orden el estado del contrato, empezando desde 0

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        uint256 raised;
        Status status;
        bool withdrawn;    
    }

    Campaign[] private campaigns;

    mapping (uint256 => mapping(address => uint256)) public contributions;

    function createCampaign(uint256 goal, uint256 durationSeconds) external returns (uint256 CampaignId) {
        require(goal > 0, "Goal must be > 0");
        require(durationSeconds > 0, "Duration must be > 0");

        uint256 deadline = block.timestamp + durationSeconds;

        campaigns.push(Campaign({
            creator: msg.sender,
            goal: goal,
            deadline: deadline,
            raised: 0,
            status: Status.Active,
            withdrawn: false
        }));
        CampaignId = campaigns.length - 1;
    }
}