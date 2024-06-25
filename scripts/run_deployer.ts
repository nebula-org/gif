import { Deployer } from "../typechain-types";
import { getNamedAccounts } from "./libs/accounts";
import { deployContract } from "./libs/deployment";
import { logger } from "./logger";

async function main() {
    logger.info("deploying components ...");
    const { instanceOwner, distributionOwner } = await getNamedAccounts();

    const amountLibAddress = process.env.AMOUNTLIB_ADDRESS;
    const feeLibAddress = process.env.FEELIB_ADDRESS;
    const nftIdLibAddress = process.env.NFTIDLIB_ADDRESS;
    const referralLibAddress = process.env.REFERRALLIB_ADDRESS;
    const riskIdLibAddress = process.env.RISKIDLIB_ADDRESS;
    const roleIdLibAddress = process.env.ROLEIDLIB_ADDRESS;
    const secondsLibAddress = process.env.SECONDSLIB_ADDRESS;
    const strLibAddress = process.env.STRLIB_ADDRESS;
    const timestampLibAddress = process.env.TIMESTAMPLIB_ADDRESS;
    const ufixedLibAddress = process.env.UFIXEDLIB_ADDRESS;
    const versionPartLibAddress = process.env.VERSIONPARTLIB_ADDRESS;

    const registryAddress = process.env.REGISTRY_ADDRESS;
    
    console.log(`Registry address: ${registryAddress}`);
    
    const { address: distributionLibAddress } = await deployContract(
        "DistributionDeployer",
        distributionOwner,
        [],
        {
            "libraries": {
                "AmountLib": amountLibAddress,
                "NftIdLib": nftIdLibAddress,
                "ReferralLib": referralLibAddress,
                "RoleIdLib": roleIdLibAddress,
                "SelectorLib": secondsLibAddress,
                "StrLib": strLibAddress,
                "TimestampLib": timestampLibAddress,
                "VersionPartLib": versionPartLibAddress,
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
        [
            registryAddress!,
            "44"
        ],
        {
            "libraries": {
                "AmountLib": amountLibAddress,
                "FeeLib": feeLibAddress,
                "DistributionDeployer": distributionLibAddress,
                "NftIdLib": nftIdLibAddress,
                "PoolDeployer": poolLibAddress,
                "ProductDeployer": productLibAddress,
                "ReferralLib": referralLibAddress,
                "RiskIdLib": riskIdLibAddress,
                "RoleIdLib": roleIdLibAddress,
                "SecondsLib": secondsLibAddress,
                "TimestampLib": timestampLibAddress,
                "UFixedLib": ufixedLibAddress,
            }
        });

    const deployer = deployerContract as unknown as Deployer;

    const instanceAddress = await deployer.getInstance();
    const instanceNftId = await deployer.getInstanceNftId();
    const distributionAddress = await deployer.getDistribution();
    const poolAddress = await deployer.getPool();
    const productAddress = await deployer.getProduct();
    const distributionNftId = await deployer.getDistributionNftId();
    const poolNftId = await deployer.getPoolNftId();
    const productNftId = await deployer.getProductNftId();
    const usdcMockAddress = await deployer.getUsdc();

    logger.info(`Instance created at ${instanceAddress} with NFT ID ${instanceNftId}`);
    logger.info(`USDC mock deployed at ${usdcMockAddress}`);
    logger.info(`Deployer deployed at ${deployerAddress}`);
    logger.info(`Distribution deployed at ${distributionAddress} with NFT ID ${distributionNftId}`);
    logger.info(`Pool deployed at ${poolAddress} with NFT ID ${poolNftId}`);
    logger.info(`Product deployed at ${productAddress} with NFT ID ${productNftId}`);

    // workaround to get script to stop
    process.exit(0);
}

main().catch((error) => {
    logger.error(error.stack);
    process.exit(1);
});
