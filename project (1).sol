// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Auction {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBindingBid;
    address public highestBidder;

    mapping(address => uint256) public bids;

    address[] public bidders;

    uint256 public bidIncrement;

    constructor(uint256 _durationMinutes, uint256 _bidIncrement) {
        require(_durationMinutes > 0, "Duration should be more than 0");
        require(_bidIncrement > 0, "Increment amount must be greater than 0");

        owner = msg.sender;
        startTime = block.timestamp;
        endTime = startTime + (_durationMinutes * 1 minutes);
        highestBindingBid = 0;
        highestBidder = address(0);
        bidIncrement = _bidIncrement;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < endTime, "Auction has ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= endTime, "Auction has not ended yet");
        _;
    }

    function placeBid() external payable onlyBeforeEnd {
        uint256 minBid = bids[highestBidder] + bidIncrement;

        require(msg.value >= minBid, "Bid must be higher than or equal to the minimum bid");

        if (bids[msg.sender] > 0) {
            uint256 refundAmount = bids[msg.sender];
            bids[msg.sender] = 0;
            payable(msg.sender).transfer(refundAmount);
        }

        bids[msg.sender] = msg.value;

        if (msg.value > highestBindingBid) {
            highestBindingBid = msg.value;
            highestBidder = msg.sender;
        }

        if (bids[msg.sender] > 0 && !hasBidder(msg.sender)) {
            bidders.push(msg.sender);
        }
    }

    function hasBidder(address bidder) internal view returns (bool) {
        for (uint256 i = 0; i < bidders.length; i++) {
            if (bidders[i] == bidder) {
                return true;
            }
        }
        return false;
    }

    function cancelAuction() external onlyOwner onlyBeforeEnd {
        
        // Refund all bidders individually
        for (uint256 i = 0; i < bidders.length; i++) {
            address bidder = bidders[i];
            uint256 refundAmount = bids[bidder];
            bids[bidder] = 0;
            payable(bidder).transfer(refundAmount);
        }
                selfdestruct(payable(owner));

    }
    

    function finalizeAuction() external onlyOwner onlyAfterEnd {
        require(highestBidder != address(0), "No bids received");

        // Transfer winning amount to the owner
        payable(owner).transfer(highestBindingBid);

       
    }

    function withdrawBid() external {
        require(block.timestamp >= endTime, "Auction has not ended yet");
        require(msg.sender != highestBidder, "You won the auction");

        uint256 amount = bids[msg.sender];
        require(amount > 0, "No bid to withdraw");

        bids[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }
}
