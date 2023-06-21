// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract NFTDutchAuction{

    address payable seller;

    uint256 public reservePrice;
    uint256 public numBlocksAuctionOpen;
    uint256 public offerPriceDecrement;


    uint256 public startingBlock;
    uint256 public endingBlock;

    bool auctionEnded = false;
    bool auctionStart = false;
    IERC721 public nft;
    uint nftTokenID;

    constructor(address erc721TokenAddress, uint256 _nftTokenId, uint _reservePrice, uint _numBlocksAuctionOpen, uint _offerPriceDecrement)
    {
        reservePrice = _reservePrice;
        numBlocksAuctionOpen = _numBlocksAuctionOpen;
        offerPriceDecrement = _offerPriceDecrement;
        nft = IERC721(erc721TokenAddress);
        nftTokenID = _nftTokenId;
    }

    function transferOwnershipNFT() public
    {
        seller = payable(msg.sender);
        
        require(nft.ownerOf(nftTokenID) == seller, "Only owner of the NFT can start the auction.");
        nft.safeTransferFrom(seller, address(this), nftTokenID);
        startingBlock = block.number;
        endingBlock = startingBlock + numBlocksAuctionOpen;
        auctionStart = true;
    }

    function bid() public payable
    {
        require(auctionStart == true, "Auction is not started yet!");
        require(auctionEnded == false && (block.number < endingBlock), "Bids are not being accepted, the auction has ended.");
        require(msg.value >= (reservePrice + (numBlocksAuctionOpen - ((block.number - startingBlock) * offerPriceDecrement))), "Your bid price is less than the required auction price.");
        
        seller.transfer(msg.value);
        nft.safeTransferFrom(address(this), msg.sender, nftTokenID);
        auctionEnded = true;
    }

    function cancelAuction() public
    {
        require(msg.sender == seller, "Invalid call, Only owner of this NFT can trigger this call.");
        require(auctionEnded == false, "Cannot halt the auction as it is successfully completed.");
        require(block.number > endingBlock, "Cannot halt the auction as it is in the process.");
        auctionEnded = true;
        nft.safeTransferFrom(address(this), seller, nftTokenID);
    }

    function onERC721Received(address operator, address from, uint tokenId, bytes calldata data) public view returns(bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}