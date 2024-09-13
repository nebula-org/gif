// SPDX-License-Identifier: APACHE-2.0
pragma solidity ^0.8.20;

import {console} from "forge-std/src/Test.sol";

import {AmountLib} from "gif-next/contracts/type/Amount.sol";
import {COLLATERALIZED, APPLIED} from "gif-next/contracts/type/StateId.sol";
import {Deployer} from "../contracts/Deployer.sol";
import {GifTest} from "gif-next/test/base/GifTest.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {UsdcMock} from "../contracts/UsdcMock.sol";

import {MyProduct} from "../contracts/MyProduct.sol";
import {MyDistribution} from "../contracts/MyDistribution.sol";
import {MyPool} from "../contracts/MyPool.sol";
import {BasicPoolAuthorization} from "gif-next/contracts/pool/BasicPoolAuthorization.sol";
import {BasicProductAuthorization} from "gif-next/contracts/product/BasicProductAuthorization.sol";

contract TestDeployer is GifTest {
    using NftIdLib for NftId;

    function setUp() public override {
        super.setUp();
    }

    function test_Deployer_apply() public {
        address testUser = makeAddr("testUser");

        // GIVEN
        vm.startPrank(registryOwner);
        token.transfer(testUser, 1000000);
        vm.stopPrank();

        vm.startPrank(testUser);

        MyDistribution distribution = new MyDistribution();
        MyPool pool = new MyPool();
        MyProduct product = new MyProduct();
        
        Deployer deployer = new Deployer(
            address(registry),
            address(distribution),
            address(pool),
            address(product),
            "test123"
        );

        RiskId riskId = deployer.getInitialRiskId();
        NftId newBundleNftId = deployer.getInitialBundleNftId();

        NftId policyNftId = deployer.applyForPolicy(testUser, riskId, 1000 * 100000, 21, newBundleNftId);

        assertTrue(policyNftId.gtz(), "policyNftId was zero");
        assertEq(chainNft.ownerOf(policyNftId.toInt()), testUser, "testUser not owner of policyNftId");

        assertTrue(deployer.getPolicyState(policyNftId) == APPLIED(), "state not APPLIED");
    }

    function test_Deployer_underwrite() public {
        address testUser = makeAddr("testUser");

        // GIVEN
        vm.startPrank(registryOwner);
        token.transfer(testUser, 1000000);
        vm.stopPrank();

        vm.startPrank(testUser);

        MyDistribution distribution = new MyDistribution();
        MyPool pool = new MyPool();
        MyProduct product = new MyProduct();

        Deployer deployer = new Deployer(
            address(registry),
            address(distribution),
            address(pool),
            address(product),
            "test123"
        );

        RiskId riskId = deployer.getInitialRiskId();
        NftId newBundleNftId = deployer.getInitialBundleNftId();

        NftId policyNftId = deployer.applyForPolicy(testUser, riskId, 1000 * 100000, 14, newBundleNftId);
        assertTrue(policyNftId.gtz(), "policyNftId was zero");
        assertEq(chainNft.ownerOf(policyNftId.toInt()), testUser, "testUser not owner of policyNftId");

        UsdcMock usdc = UsdcMock(deployer.getUsdc());
        usdc.approve(deployer.getProductTokenHandler(), 100 * 1000000);
        deployer.underwritePolicy(policyNftId, AmountLib.max());

        assertTrue(deployer.getPolicyState(policyNftId) == COLLATERALIZED(), "state not ACTIVE");
    }

}
