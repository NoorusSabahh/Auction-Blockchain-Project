// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Auction {
    address public owner;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public highestBindingBid;
    address[] public highestBidders;
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
        // Refund the bid amount only if the bidder is not the highest bidder
        if (msg.sender != highestBidder) {
            uint256 refundAmount = bids[msg.sender];
            bids[msg.sender] = 0;
            payable(msg.sender).transfer(refundAmount);
        }
    }

    bids[msg.sender] = msg.value;

    if (msg.value > highestBindingBid) {
        // Clear existing highest bidders and add the new one
        highestBidders = [msg.sender];
        highestBindingBid = msg.value;
    } else if (msg.value == highestBindingBid) {
        // Add this bidder to the list of highest bidders
        highestBidders.push(msg.sender);
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
    

    function finalizeAuction() external onlyOwner  {
        require(block.timestamp >= startTime + 2 minutes || block.timestamp >= endTime, "Auction cannot be finalized yet");
        require(bidders.length >= 3, "At least 3 bidders are required to finalize the auction");
        
         uint256 serviceCharge = (highestBindingBid * 10) / 100; // Calculate 10% service charge
        uint256 ownerProceeds = highestBindingBid - serviceCharge; // Calculate owner's proceeds

        // Transfer 90% of the highestBindingBid to the contract
        payable(address(this)).transfer(ownerProceeds);

        // Transfer 10% service charge to the owner
        payable(owner).transfer(serviceCharge);
       
       // Choose a random highest bidder if there is more than one
         if (highestBidders.length > 1) {
        uint256 randomIndex = random() % highestBidders.length;
        highestBidder = highestBidders[randomIndex];
    }

    }

    function random() internal view returns (uint) {
            return uint(keccak256(abi.encodePacked(block.timestamp, highestBidders.length)));
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
