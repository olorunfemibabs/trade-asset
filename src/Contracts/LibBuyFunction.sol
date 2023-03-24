// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "../../lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import "./priceFeed.sol";

contract Market {
    using SafeMath for uint256;

    event AssetSold(uint256 assetId);

    function returnStorage() internal pure returns(BuyStorage storage bStore) {
    bytes32 position = keccak256("payment.storage.system");
        assembly {
            bStore.slot := position
        }
    }

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

    function buyAsset(uint256 _assetId, address _token, uint256 _amount ) public payable {
         
        _swapUsdtEth(_token, _amount);

        Asset storage asset = assets[_assetId];

        require(asset.forSale, "Asset is not for sale");
        require( asset.price <= msg.value, "Insufficient funds");

        asset.owner = msg.sender;
        asset.forSale = false;

        payable(asset.owner).transfer(asset.price);

        emit AssetSold(_assetId);
    }

    function _swapUsdtEth( address _tokenA ,uint256 _amountA) internal {
        BuyStorage storage bStore = returnStorage();
        int256 priceEth = pricefeed.getLatestEthPrice();
        uint256 swapRate = (3.5 ether * uint256(priceEth)) / 1e18;
        if( bStore.decimalPerToken[_tokenA] == 0 ) revert("Only USDT is accepted for now");
        if (_amountA < swapRate) revert("Price is 3.5 ether");
        bool success = IERC20(_tokenA).transferFrom(
            msg.sender,
            address(this),
            _amountA
        );
        if (!success) revert("Withdraw Fail...!");
    }


    function _withdrawEth(address _to, uint256 _amount) internal {
        BuyStorage storage bStore = returnStorage();
        if (address(this).balance < _amount) {
            revert("Insufficient funds");
        }
        if (_to == address(0)) revert("ERROR: Invalid address");
        if (msg.sender != pStore.Admin)
            revert("Unauthorized Operation: Only Admin is authorized");
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Withdraw Fail...!");
    }

    function _withdrawToken(address _token, address _to, uint256 _amount) internal {
        BuyStorage storage bStore = returnStorage();
        if (address(this).balance < _amount) {
            revert("Insufficient funds");
        }
        if (_to == address(0)) revert("ERROR: Invalid address");
        if (msg.sender != bStore.Admin)
            revert("Unauthorized Operation: Only Admin is authorized");
        bool success = IERC20(_token).transfer(_to, _amount);
        require(success, "Withdraw Fail...!");
    }

}