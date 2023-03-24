// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "./priceFeed.sol";

contract Market {
    using SafeMath for uint256;

    struct Asset {
        uint256 price;
        address owner;
        bool forSale;
        string name;
        string description;
    }

    mapping(uint256 => Asset) public assets;

    uint256[] public assetIds;

    event AssetSold(uint256 assetId);

    function listAssetForSale( uint256 _assetId, uint256 _price, string memory _name, string memory _description ) public {

        Asset memory newAsset = Asset({
            price: _price,
            owner: msg.sender,
            forSale: true,
            name: _name,
            description: _description
        });

        assets[_assetId] = newAsset;
        assetIds.push(_assetId);
    }

    function buyAsset(uint256 _assetId) public payable {
         
        Asset storage asset = assets[_assetId];

        require(asset.forSale, "Asset is not for sale");
        require( asset.price <= msg.value, "Insufficient funds");

        asset.owner = msg.sender;
        asset.forSale = false;

        payable(asset.owner).transfer(asset.price);

        emit AssetSold(_assetId);
    }


}