# GIF-next-sandbox

## What's this?

This is a sandbox repository for the GIF-next project. It contains example components and tests for the GIF-next project.
The contracts `contracts/BasicDistribution.sol`, `contracts/BasicPool.sol` and `contracts/InsuranceProduct.sol` are examples for components that can be used in the GIF framework. 
None if them do more then expose the internal funtions right now, but they can be used as a basis to build own components. 
Additionally the contract `contracts/Deployer.sol` is a meta contract that helps to deploy and prepare a new instance just by deploying the meta contract. This is useful for trying out the components quickly. See below (section _Quickstart_) on instructions on how to do this. 

The project also contains an example foundry forge based unit test `TestInsuranceProduct.t.sol` which demonstrates how to write a test for the `InsuranceProduct` contract.

## Notes

- Renaming the contracts requires adapting the deployment script to be able to deploy the renamed contracts. The same goes for including additional libraries in the component contracts.
- Updating the GIF framework requires updating the submodule in the `gif-next` directory. Since `forge update gif-next` will always update to the latest commit on the develop branch of the `gif-next` repo. If a specific version if required, its easier to first remove the module using `forge remove gif=next` and then re-add it again using `forge install gif-next@version`. 
- Updating the GIF framework might require changes to components as well as the deployment script. 

## Quickstart

These scripts/contracts require a chain where a gif-next instance is already deployed. 

### All-in-one setup using the `Deployer` contract

_Note_: This contract can easily be deployed from Remix or a similar IDE to get up and running quickly. It can be compiled and deployed without the need for a local development environment and external dependencies (everything is self-contained in the contract/respository).

Deploy the `Deployer` contract to the chain where the GIF instance is deployed. 
The deployer contract requires the following parameters:
- `registryAddress` the address of the deployed registry
- `deploymentId` a unique id for this deployment

During the deployment the contract will 
- create a new instance on the GIF framework
- deploy a mock USDC token
- deploy the components `BasicDistribution`, `BasicPool` and `InsuranceProduct` and register them with the new instance
- create a new bundle in the pool with a coverage amount of 10000 USDC
- a new riskId for creating new policies
- transfer the ownership of the instance, components and bundle to the caller of the deployment
- transfer 10mio USDC to the caller of the deployment

Now the caller can use the functions `applyForPolicy` as well as `underwritePolicy` to create and underwrite policies on the deployed product. 
For futher details on function of the `Deployer` contract see the API documentation below.

### Deploy the contract via hardhat

run the script `scripts/run_deployer.ts` with these environment variables set: `AMOUNTLIB_ADDRESS`, `FEELIB_ADDRESS`, `NFTIDLIB_ADDRESS`, `REFERRALLIB_ADDRESS`, `RISKIDLIB_ADDRESS`, `ROLEIDLIB_ADDRESS`, `SECONDSLIB_ADDRESS`, `TIMESTAMPLIB_ADDRESS`, `UFIXEDLIB_ADDRESS`, `REGISTRY_ADDRESS`

This will deploy the `Deployer` contract and print the addresses and nfts of the deployed components. 
For futher details on function of the `Deployer` contract see the API documentation below.

## Contract `Deployer` API documentation

- `getInstance` returns the address of the created instance
- `getInstanceNftId` returns the nftId of the created instance
- `getUsdc` returns the address of the deployed USDC token
- `getDistributionNftId` returns the nftId of the deployed `BasicDistribution` component
- `getDistribution` returns the deployed `BasicDistribution` component
- `getPoolNftId` returns the nftId of the deployed `BasicPool` component
- `getPool` returns the deployed `BasicPool` component
- `getPoolTokenHandler` returns the address of the token handler of the pool component
- `getProductNftId` returns the nftId of the deployed `InsuranceProduct` component
- `getProduct` returns the deployed `InsuranceProduct` component
- `getProductTokenHandler` returns the address of the token handler of the product component

- `getInitialBundleNftId` returns the nftId of the bundle created during deployment
- `getInitialRiskId` returns the riskId created during deployment

- `createRisk` create a new riskId and return the `RiskId` object
- `sendUsdcTokens` send USDC tokens to an address
- `createBundle` create a new bundle in the pool
- `applyForPolicy` apply for a new policy and return the `nftId`. 
  When run through an rpc node (e.g. remix), the id of the `NftId` of the created policy can be extracted from the transaction log `LogRegistration` field `nftId`.
- `underwritePolicy` underwrite a policy application identified by `policyNftId` and transfer the premium amount to the bundle (requires a previous approval of the policy amount to the `productTokenHandler`)
- `getPolicyState` get the current `StateId` of a policy 
- `getBundleBalance` get the balance of the `bundleNftId`


## Hardhat/Forge Commands

### Compiling

Compiling can be done through foundry forge as well as hardhat. 

```bash
forge compile
```

```bash
npm run build
```

### Run tests

Since the example tests are written using forge, they must be run using the forge test command. 

```bash
forge test
```

### Deployment

The deployment script `scripts/deploy.ts` is hardhat based and run using the command

```bash
npm run scripts/deploy.ts
```

As a prerequisite, the GIF framework is required to be deployed on the chain and a (new) instance created (see [this script](https://github.com/etherisc/gif-next/blob/develop/scripts/deploy_all.ts) for deployment of the GIF). 
Make sure the version deployed and the version linked in this project (via Git submodules) are compatible.
Also these environment variables must be set (e.g. in a `.env` file):

- `AMOUNTLIB_ADDRESS` is the address of the AmountLib contract
- `FEELIB_ADDRESS` is the address of the FeeLib contract
- `NFTIDLIB_ADDRESS` is the address of the NftIdLib contract
- `REFERRALLIB_ADDRESS` is the address of the ReferralLib contract
- `RISKIDLIB_ADDRESS` is the address of the RiskIdLib contract
- `ROLEIDLIB_ADDRESS` is the address of the RoleIdLib contract
- `SECONDSLIB_ADDRESS` is the address of the SecondsLib contract
- `TIMESTAMPLIB_ADDRESS` is the address of the TimestampLib contract
- `UFIXEDLIB_ADDRESS` is the address of the UFixedLib contract
- `REGISTRY_ADDRESS` is the address of the GIF registry

The values can be takes from the output of the deployment of the GIF framework.

To deploy to a different chain, configure it in `hardhat.config.ts` and run the deployment script with the `--network` flag. 

## Documentation

Find the documentation of the next GIF version at https://docs.etherisc.com/gif-next/3.x/ 


## Setup of the development environment

### Prerequisites

- A running Docker instance (or other compatible container engine) 
- Visual Studio Code (VS Code) with the [Remote Development Extension Pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.vscode-remote-extensionpack) installed
- Know how to work with [devcontainers](https://code.visualstudio.com/docs/devcontainers/containers)  (optional) 

Installing Docker on Windows is sometimes a struggle.
Recommended Approach: Follow the installation instructions for https://docs.docker.com/desktop/install/windows-install/[Docker Desktop].
Installing Docker on [Linux](https://docs.docker.com/desktop/install/linux-install/) or [Mac](https://docs.docker.com/desktop/install/mac-install/) should be straight forward.

### Get the source code and editor ready

- Fork the https://github.com/etherisc/gif-next-sandbox to your own github account (if you want to be able to commit changes)
- Clone the repository to your local machine
- Open the repository in VS Code

There are three ways to work with the sandbox (described below)

- Use the devcontainer provided in the repository
- Use Github Codespaces

### Start the sandbox devcontainer

- Start the devcontainer (either wait for the pop to build the devcontainer or open the command list (F1) and select the command _Dev Containers: Rebuild and reopen in container_) 
- Wait for the devcontainer to finish compiling and deploying the contracts

### Use Github Codespaces

Github Codespaces is a new feature of Github that allows you to work with a repository in a container environment hosted by Github.
To use Github Codespaces you need to have a Github account and you need to be logged in to Github.
Open the https://github.com/etherisc/gif-next-sandbox repository in your browser and click on the button `Code` and select `Open with Codespaces` from the dropdown menu. 
This will open a new browser tab with the sandbox repository in a devcontainer hosted by Github.
You can now work with the sandbox repository in the browser (or open the codespace in VS Code by clicking on the button `Open with VS Code` in the upper right corner of the browser tab).

To improve performance of the codespace you can change the machine type in the codespace settings.
