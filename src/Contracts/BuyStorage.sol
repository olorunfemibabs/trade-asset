// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

    struct Asset {
        uint256 price;
        address owner;
        bool forSale;
        string name;
        string description;
    }

    struct BuyVar {

        mapping(uint256 => Asset) assets;

        uint256[] assetIds;
    }