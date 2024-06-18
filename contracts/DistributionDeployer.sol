// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {BasicDistribution} from "./BasicDistribution.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";

library DistributionDeployer {

    function deployDistribution(address registry,
            NftId instanceNftId,
            address initialDistributionOwner,
            string memory deploymentId,
            address token) public returns (BasicDistribution) {
        return new BasicDistribution(
            registry,
            instanceNftId,
            initialDistributionOwner,
            string.concat("BasicDistribution", deploymentId),
            token,
            "",
            ""
        );
    }
}
