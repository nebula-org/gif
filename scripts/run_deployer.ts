import { AddressLike, Signer, encodeBytes32String } from "ethers";
import { AccessManagerExtendedInitializeable__factory, BasicDistribution, Deployer, Distribution, IInstance__factory, Pool, Product } from "../typechain-types";
import { getNamedAccounts } from "./libs/accounts";
import { deployContract } from "./libs/deployment";
import { DISTRIBUTION_OWNER_ROLE, POOL_OWNER_ROLE, PRODUCT_OWNER_ROLE } from "./libs/gif_constants";
import { executeTx } from "./libs/transaction";
import { logger } from "./logger";
import { deployAndRegisterMasterInstance } from "../lib/gif-next/scripts/libs/instance";

async function main() {
    logger.info("deploying components ...");
    const { instanceOwner, distributionOwner } = await getNamedAccounts();

    const amountLibAddress = process.env.AMOUNTLIB_ADDRESS;
    const feeLibAddress = process.env.FEELIB_ADDRESS;
    const nftIdLibAddress = process.env.NFTIDLIB_ADDRESS;
    const referralLibAddress = process.env.REFERRALLIB_ADDRESS;
    const roleIdLibAddress = process.env.ROLEIDLIB_ADDRESS;
    const ufixedLibAddress = process.env.UFIXEDLIB_ADDRESS;
    
    const instanceNftId = process.env.INSTANCE_NFTID;
    const instanceAddress = process.env.INSTANCE_ADDRESS;
    
    const instance = IInstance__factory.connect(instanceAddress!, instanceOwner);
    const instanceAccessManagerAddress = await instance.getInstanceAccessManager();
    const registryAddress = await instance.getRegistry();
    const instanceAccessManager = AccessManagerExtendedInitializeable__factory.connect(instanceAccessManagerAddress, instanceOwner);
    await executeTx(() => instanceAccessManager.grantRole(DISTRIBUTION_OWNER_ROLE, distributionOwner.address, 0));
    console.log(`Distribution owner role granted to ${distributionOwner.address} at ${instanceAccessManagerAddress}`);
    await executeTx(() => instanceAccessManager.grantRole(POOL_OWNER_ROLE, distributionOwner.address, 0));
    console.log(`Pool owner role granted to ${distributionOwner.address} at ${instanceAccessManagerAddress}`);
    await executeTx(() => instanceAccessManager.grantRole(PRODUCT_OWNER_ROLE, distributionOwner.address, 0));
    console.log(`Product owner role granted to ${distributionOwner.address} at ${instanceAccessManagerAddress}`);

    const { address: distributionLibAddress } = await deployContract(
        "DistributionDeployer",
        distributionOwner,
        [],
        {
            "libraries": {
                "AmountLib": amountLibAddress,
                "NftIdLib": nftIdLibAddress,
                "ReferralLib": referralLibAddress,
            }
        });
    const { address: poolLibAddress } = await deployContract(
        "PoolDeployer",
        distributionOwner,
        [],
        {
            "libraries": {
                "AmountLib": amountLibAddress,
                "FeeLib": feeLibAddress,
                "NftIdLib": nftIdLibAddress,
                "RoleIdLib": roleIdLibAddress,
                "UFixedLib": ufixedLibAddress,
            }
        });
    const { address: productLibAddress } = await deployContract(
        "ProductDeployer",
        distributionOwner,
        [],
        {
            "libraries": {
                "AmountLib": amountLibAddress,
                "FeeLib": feeLibAddress,
                "NftIdLib": nftIdLibAddress,
            }
        });
    
    const { address: deployerAddress, contract: deployerContract } = await deployContract(
        "Deployer",
        distributionOwner,
        // [],
        [
            registryAddress!,
            instanceNftId,
            distributionOwner,
            distributionOwner,
            distributionOwner,
            "42"
        ],
        {
            "libraries": {
                "DistributionDeployer": distributionLibAddress,
                "PoolDeployer": poolLibAddress,
                "ProductDeployer": productLibAddress
            }
        });

    const deployer = deployerContract as unknown as Deployer;

    const distributionAddress = await deployer.getDistribution();
    const poolAddress = await deployer.getPool();
    const productAddress = await deployer.getProduct();
    const distributionNftId = await deployer.getDistributionNftId();
    const poolNftId = await deployer.getPoolNftId();
    const productNftId = await deployer.getProductNftId();
    const usdcMockAddress = await deployer.getUsdc();

    logger.info(`Deployer deployed at ${deployerAddress}`);
    logger.info(`Distribution deployed at ${distributionAddress} with NFT ID ${distributionNftId}`);
    logger.info(`Pool deployed at ${poolAddress} with NFT ID ${poolNftId}`);
    logger.info(`Product deployed at ${productAddress} with NFT ID ${productNftId}`);
    logger.info(`USDC mock deployed at ${usdcMockAddress}`);

    // workaround to get script to stop
    process.exit(0);
}

main().catch((error) => {
    logger.error(error.stack);
    process.exit(1);
});
