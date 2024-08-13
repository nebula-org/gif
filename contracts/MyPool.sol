// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {BasicPool} from "gif-next/contracts/pool/BasicPool.sol";
import {Fee} from "gif-next/contracts/type/Fee.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {Seconds} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed} from "gif-next/contracts/type/UFixed.sol";

contract MyPool is BasicPool {

    function initialize(
        address registry,
        NftId productNftId,
        address token,
        IComponents.PoolInfo memory poolInfo,
        IAuthorization authorization,
        address initialOwner,
        string memory name
    )
        public
        virtual
        initializer()
    {
        _initializeBasicPool(
            registry,
            productNftId,
            name,
            token,
            poolInfo,
            authorization,
            initialOwner);
    }

    function createBundle(
        address owner,
        Fee memory fee,
        uint256 initialAmount,
        Seconds lifetime,
        bytes calldata filter
    )
        external
        virtual 
        returns(NftId bundleNftId)
    {
        bundleNftId = _createBundle(
            owner,
            fee,
            lifetime,
            filter
        );
        _stake(bundleNftId, AmountLib.toAmount(initialAmount));
    }

}