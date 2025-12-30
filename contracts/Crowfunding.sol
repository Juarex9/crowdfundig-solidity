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

    function contribute(uint256 campaignId) external payable {
        require(campaignId < campaigns.length, "Invalid campaign");

        Campaign storage c = campaigns[campaignId];

        require(c.status == Status.Active, "Campaign not active");
        require(block.timestamp < c.deadline, "Campaign ended");
        require(msg.value > 0, "Must send ETH");

        c.raised += msg.value;
        contributions[campaignId][msg.sender] += msg.value;
    }

    function campaignsCount() external view returns (uint256) {
        return campaigns.length;
    }

    function getCampaign(uint256 campaignId)
        external 
        view 
        returns (
            address creator,
            uint256 goal,
            uint256 deadline,
            uint256 raised,
            Status status,
            bool withdrawn
        )
    {
        require(campaignId < campaigns.length, "Invalid campaign");
        Campaign storage c = campaigns[campaignId];

        return (c.creator, c.goal, c.deadline, c.raised, c.status, c.withdrawn);
    }

    function finalize(uint256 campaignId) external {
        require(campaignId < campaigns.length, "Invalid campaign");

        Campaign storage c = campaigns[campaignId];

        require(c.status == Status.Active, "Already finalized");
        require(block.timestamp >= c.deadline, "Campaign still active");

        if (c.raised >= c.goal) {
            c.status = Status.Successful;
        } else {
            c.status = Status.Failed;
        }
    }

    function withdraw(uint256 campaignId) external {
        require(campaignId < campaigns.length, "Invalid campaign");

        Campaign storage c = campaigns[campaignId];

        require(c.status == Status.Successful, "Campaign not successful");
        require(msg.sender == c.creator, "Not campaign creator");
        require(!c.withdrawn, "Already withdrawn");

        uint256 amount = c.raised;
        require(amount > 0, "Nothing to withdraw");

        //effects
        c.withdrawn = true;
        c.raised = 0;

        //interaction
        (bool ok, ) = payable(c.creator).call{value: amount}("");
        require(ok, "ETH transfer failed");
    }
    
    function refund(uint256 campaignId) external {
        require(campaignId < campaigns.length, "Invalid campaign");

        Campaign storage c = campaigns[campaignId];
        require(c.status == Status.Failed, "Campaign not failed");

        uint256 contributed = contributions[campaignId][msg.sender];
        require(contributed > 0, "Nothing to refund");

        //effects
        contributions[campaignId][msg.sender] = 0;

        //interaction
        (bool ok, ) = payable(msg.sender).call{value: contributed}("");
        require(ok, "Refund failed");
    }
}