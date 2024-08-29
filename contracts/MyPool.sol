// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Amount, AmountLib} from "gif-next/contracts/type/Amount.sol";
import {BasicPool} from "gif-next/contracts/pool/BasicPool.sol";
import {Fee, FeeLib} from "gif-next/contracts/type/Fee.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";
import {IComponents} from "gif-next/contracts/instance/module/IComponents.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {Seconds} from "gif-next/contracts/type/Timestamp.sol";
import {UFixed, UFixedLib} from "gif-next/contracts/type/UFixed.sol";

contract MyPool is BasicPool {
    
    function initialize(
        address registry,
        NftId productNftId,
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
            IComponents.PoolInfo({
                maxBalanceAmount: AmountLib.max(),
                isInterceptingBundleTransfers: false,
                isProcessingConfirmedClaims: false,
                isExternallyManaged: false,
                isVerifyingApplications: false,
                collateralizationLevel: UFixedLib.one(),
                retentionLevel: UFixedLib.one()
            }),
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

    function approveTokenHandler(IERC20Metadata token, Amount amount) 
        external 
        restricted() 
        onlyOwner() 
    { 
        _approveTokenHandler(token, amount); 
    }


}