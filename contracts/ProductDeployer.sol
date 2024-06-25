// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {MyProduct} from "./MyProduct.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";
import {BasicDistributionAuthorization} from "gif-next/contracts/distribution/BasicDistributionAuthorization.sol";
import {BasicPoolAuthorization} from "gif-next/contracts/pool/BasicPoolAuthorization.sol";
import {BasicProductAuthorization} from "gif-next/contracts/product/BasicProductAuthorization.sol";
import {IAuthorization} from "gif-next/contracts/authorization/IAuthorization.sol";

library ProductDeployer {

    function deployProduct(
            address registry,
            NftId instanceNftId,
            address owner,
            string memory name,
            IAuthorization auth,
            address token,
            address poolAddress,
            address distributionAddress) public returns (MyProduct) {
        return new MyProduct(
            registry,
            instanceNftId,
            auth,
            owner,
            name,
            token,
            false, // isInterceptor
            poolAddress,
            distributionAddress
        );
    }
}