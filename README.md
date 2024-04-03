# Example GIF-next Project

This repository contains example components for a GIF-next project. 
There are the `contracts/BasicDistribution.sol`, `contracts/BasicPool.sol` and `contracts/InsuranceProduct.sol` contracts. 
None if them do more then expose the internal funtions right now, but they can be used as a basis to build own components. 

The project also contains an example foundry forge based unit test `TestInsuranceProduct.t.sol` which demonstrates how to write a test for the `InsuranceProduct` contract.

## Notes

- Renaming the contracts requires adapting the deployment script to be able to deploy the renamed contracts. The same goes for including additional libraries in the component contracts.
- Updating the GIF framework requires updating the submodule in the `gif-next` directory. Since `forge update gif-next` will always update to the latest commit on the develop branch of the `gif-next` repo. If a specific version if required, its easier to first remove the module using `forge remove gif=next` and then re-add it again using `forge install gif-next@version`. 
- Updating the GIF framework might require changes to components as well as the deployment script. 

## Commands

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
- `ROLEIDLIB_ADDRESS` is the address of the RoleIdLib contract
- `UFIXEDLIB_ADDRESS` is the address of the UFixedLib contract
- `INSTANCE_ADDRESS` is the address of the Gif instance to register the components to
- `INSTANCE_NFTID` is the nftId of the Gif instance

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
