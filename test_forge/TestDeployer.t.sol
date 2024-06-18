// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.20;

import {ACTIVE, APPLIED} from "gif-next/contracts/type/StateId.sol";
import {Deployer} from "../contracts/Deployer.sol";
import {GifTest} from "gif-next/test/base/GifTest.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {UsdcMock} from "../contracts/UsdcMock.sol";


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

        Deployer deployer = new Deployer(
            address(registry),
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

        Deployer deployer = new Deployer(
            address(registry),
            "test123"
        );

        RiskId riskId = deployer.getInitialRiskId();
        NftId newBundleNftId = deployer.getInitialBundleNftId();

        NftId policyNftId = deployer.applyForPolicy(testUser, riskId, 1000 * 100000, 14, newBundleNftId);
        assertTrue(policyNftId.gtz(), "policyNftId was zero");
        assertEq(chainNft.ownerOf(policyNftId.toInt()), testUser, "testUser not owner of policyNftId");

        UsdcMock usdc = UsdcMock(deployer.getUsdc());
        usdc.approve(deployer.getProductTokenHandler(), 100 * 1000000);
        deployer.underwritePolicy(policyNftId);

        assertTrue(deployer.getPolicyState(policyNftId) == ACTIVE(), "state not ACTIVE");
    }

}
