//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";


contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    
    address payable owner;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool isSold; 
    }

    uint256 listingPrice = 0.0015 ether;

    mapping(uint256 => MarketItem) private idMarketItem;

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool isSold
    );


    constructor() ERC721("Asiwaju Nft", "ASJ") {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner can");
        _;
    }

    /*updates the listing price of the contract */
    function updateListingPrice(uint256 _listingPrice) 
        public 
        payable 
        onlyOwner 
        {
            listingPrice = _listingPrice;
        }


        /*returns the listing price of the contract */
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    //create a "create nft token function"
    /*mints a token and lists it in the marketplace */

    function createToken(string memory tokenURI, uint256 price) 
        public 
        payable 
        returns(uint256) 
    {

        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    } 

    //creating market items
    function createMarketItem(uint tokenId, uint price) private {
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingPrice, "Price must be equal to Listing Price");
        
         idMarketItem[tokenId] = MarketItem (
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
         );

         _transfer(msg.sender, address(this), tokenId);

         emit idMarketItemCreated(
                tokenId, 
                msg.sender, 
                address(this), 
                price, 
                false 
            );


    }

    //creating function for resale token
    /*allows someone to resell a token they have purchased */
    function reSellToken(uint256 tokenId, uint256 price) public payable {
        require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can resell");
        require(msg.value == listingPrice, "Price must equal the listing price");

        idMarketItem[tokenId].isSold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);

    }


    //creating function createmarketsale
    /* creates the sale of a marketplace item */
    /* transfer ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
            uint256 price = idMarketItem[tokenId].price;

            require(msg.value == price, "Ensure to submit the asking price to complete the purchase");

            idMarketItem[tokenId].owner = payable(msg.sender);
            idMarketItem[tokenId].isSold = true;
            idMarketItem[tokenId].seller = payable(address(0));

            _itemsSold.increment();
            
            _transfer(address(this), msg.sender, tokenId);

            payable(owner).transfer(listingPrice);
            payable(idMarketItem[tokenId].seller).transfer(msg.value);
        }

        //getting unsold nft data
        /*returns all unsold market items */
        function fetchMarketItem() public view returns(MarketItem[] memory) {
            uint256 itemCount =_tokenIds.current();
            uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
            uint256 currentIndex =0;

            MarketItem[] memory items = new MarketItem[](unSoldItemCount);
            for(uint256 i = 0; i < itemCount; i++) {
                if(idMarketItem[i + 1].owner == address(this)) {
                    uint256 currentId = i + 1;

                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;

                }
            }
            return items;
        }


        //purchase item
        /* returns only items that a user has purchased */
        function fetchMyNFT() public view returns(MarketItem[] memory) {
            uint256 totalItemCount = _tokenIds.current();
            uint256 itemCount = 0;
            uint256 currentIndex = 0;

            for(uint256 i = 0; i < totalItemCount; i++) {
                if(idMarketItem[i + 1].owner == msg.sender){
                    itemCount += 1;
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint256 i = 0; i < totalItemCount; i++) {
                if(idMarketItem[i + 1]. owner == msg.sender) {
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items;
        }

        //a singular item of the user
        /* returns only items a user has listed */
        function fetchItemsListed() public view returns (MarketItem[] memory) {
            uint256 totalItemCount = _tokenIds.current();
            uint256 itemCount = 0;
            uint256 currentIndex = 0;

            for(uint256 i = 0; i < totalItemCount; i++) {
                if(idMarketItem[i + 1].seller == msg.sender) {
                    itemCount += 1;
                }
            }

            MarketItem[] memory items = new MarketItem[](itemCount);
            for( uint256 i = 0; i < totalItemCount; i++) {
                if(idMarketItem[i + 1].seller == msg.sender) {
                    uint256 currentId = i + 1;

                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }

            return items;
        } 

} 