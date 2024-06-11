// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {InsuranceProduct} from "./InsuranceProduct.sol";
import {NftId} from "gif-next/contracts/type/NftId.sol";

// library ProductDeployer {

//     function deployProduct(address registry,
//             NftId instanceNftId,
//             address initialProductOwner,
//             string memory deploymentId,
//             address token,
//             address poolAddress,
//             address distributionAddress) public returns (InsuranceProduct) {
//         return new InsuranceProduct(
//             registry,
//             instanceNftId,
//             initialProductOwner,
//             string.concat("InsuranceProduct", deploymentId),
//             token,
//             false,
//             poolAddress,
//             distributionAddress,
//             "",
//             ""
//         );
//     }

// }