// SPDX-License-Identifier: APACHE-2.0
pragma solidity 0.8.20;

import {console} from "forge-std/src/Test.sol";

import {ACTIVE, APPLIED} from "gif-next/contracts/type/StateId.sol";
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

    function test_DeployerSetUp() public {
        address testUser = makeAddr("testUser");
        vm.startPrank(testUser);
        Deployer deployer = new Deployer(
            address(registry),
            "test123"
        );
        // solhint-disable
        console.log("Deployer creation code length", type(Deployer).creationCode.length);
        console.log("Deployer runtime code length", type(Deployer).runtimeCode.length);

        console.log("My product creation code length", type(MyProduct).creationCode.length);
        console.log("My product runtime code length", type(MyProduct).runtimeCode.length);
        console.log("BasicProductAuthorization creation code length", type(BasicProductAuthorization).creationCode.length);
        console.log("BasicProductAuthorization runtime code length", type(BasicProductAuthorization).runtimeCode.length);

        console.log("My pool creation code length", type(MyPool).creationCode.length);
        console.log("My pool runtime code length", type(MyPool).runtimeCode.length);
        console.log("BasicPoolAuthorization creation code length", type(BasicPoolAuthorization).creationCode.length);
        console.log("BasicPoolAuthorization runtime code length", type(BasicPoolAuthorization).runtimeCode.length);

        console.log("My distribution creation code length", type(MyDistribution).creationCode.length);
        console.log("My distribution runtime code length", type(MyDistribution).runtimeCode.length);
        // solhint-enable
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
