// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./NFT.sol";

contract NFTMarket is ReentrancyGuard, Ownable, IERC721Receiver  {
    using Counters for Counters.Counter;
    Counters.Counter private _auctionIds;
    address payable marketWallet;

    struct MarketItem {
    //uint itemId;
    address nftContract;
    uint tokenId;
    address payable seller;
    address payable owner;
    string tokenType;
    uint256 price;
    bool sold;
    }

    struct tokenToAuctionDetails {
        uint auctionId;
        address seller;
        uint256 price;
        uint256 duration;
        uint256 maxBid;
        address maxBidUser;
        bool isActive;
        uint256[] bidAmounts;
        address[] users;
    }
    mapping(address => mapping(uint256 => MarketItem)) private idToMarketItem;
    mapping(address => mapping(uint256 => tokenToAuctionDetails)) public tokenToAuction;
    mapping(uint256 => mapping(address => mapping(uint256 => mapping(address => uint256)))) public bids;

    event MarketItemCreated (
    uint indexed itemId,
    address indexed nftContract,
    uint256 indexed tokenId,
    address seller,
    address owner,
    uint256 price,
    bool sold
    );

    event AuctionId (
      uint indexed auctionId
    );

    constructor () {
        marketWallet = payable(0xFD2A265360206390ffd09Dfe4e1382559F82B9Ec);
    }

    function createTokenAuction(address _nft,uint256 _tokenId,uint256 _price,uint256 _duration, uint isItem) public payable {
        require(msg.sender != address(0), "Inv Addr");
        require(_nft != address(0), "Inv Acc");
        require(_price > 0, "more than 0");
        require(_duration > 0, "Inv duration ");
        if (isItem == 1) marketWallet.transfer(msg.value);
        _auctionIds.increment();
        uint256 auctionId = _auctionIds.current();
        tokenToAuctionDetails memory _auction = tokenToAuctionDetails(
           auctionId,msg.sender, _price, _duration, 0, address(0), true, new uint256[](0), new address[](0)
        );
        //ERC721(_nft).transferFrom(owner, address(this), _tokenId);
        tokenToAuction[_nft][_tokenId] = _auction;
        idToMarketItem[_nft][_tokenId].tokenType = "auction";
        idToMarketItem[_nft][_tokenId].sold = false;
        idToMarketItem[_nft][_tokenId].seller = payable(address(this));
        emit AuctionId(auctionId);
    }

  function createMarketItem(address nftContract, uint256 tokenId, uint256 price, string memory tokenType, uint256 _duration, uint isItem) public payable nonReentrant {
    address _owner = IERC721(nftContract).ownerOf(tokenId); 
    require(_owner == msg.sender, "no nft owner");
    marketWallet.transfer(msg.value);
    idToMarketItem[nftContract][tokenId] =  MarketItem(nftContract,tokenId,payable(address(this)),payable(msg.sender),tokenType,price,false);
    if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("auction"))) {
       createTokenAuction(nftContract, tokenId, price, _duration, isItem);
    } 
     emit MarketItemCreated(
      tokenId, nftContract, tokenId, msg.sender, msg.sender, price, false
    ); 
  }

  function createMarketSale(address nftContract, uint256 itemId, uint fee) public payable nonReentrant {
    uint tokenId = idToMarketItem[nftContract][itemId].tokenId;
    address _owner = IERC721(nftContract).ownerOf(itemId);
    idToMarketItem[nftContract][itemId].owner.transfer(msg.value - (fee));
    marketWallet.transfer(fee);
    IERC721(nftContract).transferFrom(_owner, msg.sender, tokenId);
    idToMarketItem[nftContract][itemId].owner = payable(msg.sender);
    idToMarketItem[nftContract][itemId].seller = payable(msg.sender);
    idToMarketItem[nftContract][itemId].sold = true;
  }

  function resellNFT(address nftContract,  uint _itemId, uint _price) public payable nonReentrant{
    marketWallet.transfer(msg.value);
    MarketItem memory _item = idToMarketItem[nftContract][_itemId];
      _item.seller = payable(msg.sender);
      _item.price = _price;
      _item.sold = false;
      idToMarketItem[nftContract][_itemId] = _item;
  }

  function cancelResellNFT(address nftContract, uint _itemId) public payable nonReentrant{
    MarketItem memory _item = idToMarketItem[nftContract][_itemId];
    marketWallet.transfer(msg.value);
    _item.seller = payable(msg.sender);
    _item.sold = true;
    idToMarketItem[nftContract][_itemId] = _item;
  }

  function giftNTF(address nftContract, address giftAddress, uint _itemId) public payable nonReentrant{
    address _owner = IERC721(nftContract).ownerOf(_itemId);
    require(_owner == msg.sender, "Debe ser el propietario del NFT para poder transferirlo.");
    MarketItem memory _item = idToMarketItem[nftContract][_itemId];
    _item.seller = payable(giftAddress);
    _item.owner = payable(giftAddress);
    _item.sold = true;
    IERC721(nftContract).transferFrom(_owner, giftAddress, _itemId);
    idToMarketItem[nftContract][_itemId] = _item;
  } 

  function fetchNFT(address nftContract, uint _itemId) public view returns (MarketItem memory) {
    return idToMarketItem[nftContract][_itemId];
  }
  
  function bid(uint256 auctionId, address _nft, uint256 _tokenId) external payable {
        tokenToAuctionDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(msg.value >= auction.price, "bid less price");
        require(auction.isActive, "not active");
        require(auction.duration > block.timestamp, "Deadline passed");
        if (bids[auctionId][_nft][_tokenId][msg.sender] > 0) {
            (bool success, ) = msg.sender.call{value: bids[auctionId][_nft][_tokenId][msg.sender]}("");
            require(success);
        }
        bids[auctionId][_nft][_tokenId][msg.sender] = msg.value;
        if (auction.bidAmounts.length == 0) {
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        } else {
            uint256 lastIndex = auction.bidAmounts.length - 1;
            require(auction.bidAmounts[lastIndex] < msg.value, "Current bid is your bid");
            auction.maxBid = msg.value;
            auction.maxBidUser = msg.sender;
        }
        uint256 inArray = 0;
        for (uint i=0; i < auction.users.length; i++) {
           if (msg.sender == auction.users[i]) {
             inArray++;
          }
        }
        if (inArray == 0)  auction.users.push(msg.sender); 
        auction.bidAmounts.push(msg.value);
    }
    
    function executeSale(uint256 auctionId, address _nft, uint256 _tokenId) external payable {
        tokenToAuctionDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.duration <= block.timestamp, "Deadline not pass");
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        marketWallet.transfer(msg.value);
        address _owner = IERC721(_nft).ownerOf(_tokenId);
        auction.isActive = false;
        if (auction.bidAmounts.length == 0) {
            idToMarketItem[_nft][_tokenId].tokenType = "listing";
            idToMarketItem[_nft][_tokenId].owner = payable(_owner);
            idToMarketItem[_nft][_tokenId].seller = payable(_owner);
            idToMarketItem[_nft][_tokenId].sold = true;
        } else {
            (bool exitosa, ) = auction.seller.call{value: auction.maxBid}("");
            require(exitosa);
            for (uint256 i = 0; i < auction.users.length; i++) {
                if (auction.users[i] != auction.maxBidUser) {
                    (bool success,) = auction.users[i].call{value: bids[auctionId][_nft][_tokenId][auction.users[i]]}("");
                    require(success);
                }
            }
            ERC721(_nft).transferFrom(
                _owner,
                auction.maxBidUser,
                _tokenId
            );
            idToMarketItem[_nft][_tokenId].tokenType = "listing";
            idToMarketItem[_nft][_tokenId].owner = payable(auction.maxBidUser);
            idToMarketItem[_nft][_tokenId].seller = payable(auction.maxBidUser);
            idToMarketItem[_nft][_tokenId].sold = true;
            idToMarketItem[_nft][_tokenId].price = auction.maxBid;
        }  
    }

    function cancelAuction(uint256 auctionId, address _nft, uint256 _tokenId) external payable {
        tokenToAuctionDetails storage auction = tokenToAuction[_nft][_tokenId];
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        marketWallet.transfer(msg.value);
        auction.isActive = false;
        for (uint256 i = 0; i < auction.users.length; i++) {
          (bool success,) = auction.users[i].call{value: bids[auctionId][_nft][_tokenId][auction.users[i]]}("");        
          require(success);
        }
        idToMarketItem[_nft][_tokenId].tokenType = "listing";
        idToMarketItem[_nft][_tokenId].owner = payable(auction.seller);
        idToMarketItem[_nft][_tokenId].seller = payable(auction.seller);
        idToMarketItem[_nft][_tokenId].sold = true;
    }

    function getTokenAuctionDetails(address _nft, uint256 _tokenId) public view returns (tokenToAuctionDetails memory) {
        tokenToAuctionDetails memory auction = tokenToAuction[_nft][_tokenId];
        return auction;
    }

    function updateTokenCorruptData(address nftContract, uint _itemId, address nftOwner, string memory tokenType) public {
      address _owner = IERC721(nftContract).ownerOf(_itemId);
      if (_owner == nftOwner) {
        MarketItem memory _item = idToMarketItem[nftContract][_itemId];
        _item.owner = payable(nftOwner);
        _item.sold = true;
        _item.seller = payable(nftOwner);
        _item.tokenType = tokenType;
        if (keccak256(abi.encodePacked(tokenType)) == keccak256(abi.encodePacked("auction"))) {
          _item.seller = payable(address(this));
          _item.sold = false;
        }
        idToMarketItem[nftContract][_itemId] = _item;
      }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )external override returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    receive() external payable {}

}