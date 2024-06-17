// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.20;

import {APPLIED} from "gif-next/contracts/type/StateId.sol";
import {NftId, NftIdLib} from "gif-next/contracts/type/NftId.sol";
import {RiskId} from "gif-next/contracts/type/RiskId.sol";
import {GifTest} from "gif-next/test/base/GifTest.sol";

import {Deployer} from "../contracts/Deployer.sol";
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

        // TODO: move ownership of instance to testUser
        // TODO: move all usdcmocks to testUser
        // TODO: create bundle for testuser

        Deployer deployer = new Deployer(
            address(registry),
            "test123"
        );

        deployer.sendUsdcTokens(testUser);
        RiskId riskId = deployer.initializeComponents("4711");
        UsdcMock usdc = deployer.getUsdc();

        usdc.approve(deployer.getPoolTokenHandler(), 10000);
        NftId newBundleNftId = deployer.createBundle(testUser, 10000, 30);

        NftId policyNftId = deployer.applyForPolicy(testUser, riskId, 1000, 21, newBundleNftId);

        assertTrue(policyNftId.gtz(), "policyNftId was zero");
        assertEq(chainNft.ownerOf(policyNftId.toInt()), testUser, "testUser not owner of policyNftId");

        assertTrue(deployer.getPolicyState(policyNftId) == APPLIED(), "state not APPLIED");
    }

}
