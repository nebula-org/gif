// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BasicPool} from "./BasicPool.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";

library PoolDeployer {

    function deployPool(address registry,
            NftId instanceNftId,
            address initialPoolOwner,
            string memory deploymentId,
            address token) public returns (BasicPool) {
        return new BasicPool(
            registry,
            instanceNftId,
            initialPoolOwner,
            string.concat("BasicPool", deploymentId),
            token,
            false,
            "",
            ""
        );
    }
}
