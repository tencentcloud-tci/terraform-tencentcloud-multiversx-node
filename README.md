# MultiversX Terraform Stack for Observer node types

This solution deploys a Terraform stack for the MultiversX observer nodes on Tencent Cloud. It uses Tencent Cloud Lighthouse as main compute service alongside other necessary resources.
The chosen Operating system is an OpenCloudOS (centOS compatible) with docker pre-installed.

Multiversx documentation: https://github.com/multiversx/mx-chain-observing-squad#observing-squad

# Choose the right observer node type 
Here are the options.

**Observer-Lite**: MultiversX Observer node with "lite" deployment mode for all 4 shards, which optimizes speed but doesn't offer access to the full blockchain history but only stores the current epoch. Usage:
 - light dApps which don't need full access to all blockchain history
 - suited for high load API calls for basic ops such as getAddress, getBalance, listAssets, etc 
 - optimized for account queries and smart contract queries

**Observer-DBlookup-HDD**: MultiversX Observer node with "db-lookup" deployment mode for all 4 shards, which balances sync speed and access to full chains history. Usage:
 - most of the dApps which need to balance speed and history
 - includes the dblookup option so can have extended block db history
 - Separate Premium HDD drives for every shard delivering up to 6000iops per disk

**Observer-DBlookup-SSD**: MultiversX Observer node with "db-lookup" deployment mode for all 4 shards, which balances sync speed and access to full chains history. Usage:
 - most of the dApps which need to balance speed and history
 - includes the dblookup option so can have extended block db history
 - Separate SSD drives for every shard delivering up to 12000iops per disk


# Features

 - The underlying compute service used is called [Tencent Cloud Lighthouse](https://www.tencentcloud.com/products/lighthouse)
 - The Cloud Accounts creation process will be streamlined for speed
 - There is an Account preparation phase which needs to be made prior to node deployment
 - The node deployment repository will be made available alongside the procedure for deployment
 - The accounts and instances are secured according Cloud and industry best practices
 - For the DB-LOOKUP nodes, their up-to-date (max 24h) snapshot is retrieved before deployment
 - The deployment of the shard processes is made in docker containers in separate “screens” (to make debugging and operation easy)
 - Integrated instance resource monitor is available in Lighthouse panel
 - All Instances have Tencent Cloud CLI and COS tools pre-installed
 - The code also includes update / delete commands

# Pre-requisites (procedures)

## Tencent Cloud Account Creation and Setup

Please follow the below procedures to set-up your Tencent Cloud Account
 - [Sign up for Tencent Cloud Account](https://www.tencentcloud.com/document/product/378/17985)
 - [Add and verify the mobile number](https://www.tencentcloud.com/document/product/378/48918)
 - [Log in with your newly created root account](https://www.tencentcloud.com/document/product/378/36004)
 - [Verify the account owner](https://www.tencentcloud.com/document/product/378/3629) (individual or enterprise)
 - [Enable login protection](https://www.tencentcloud.com/document/product/378/8392) and [operation protection](https://www.tencentcloud.com/document/product/378/10740)
 - [Enable suspicious login protection](https://www.tencentcloud.com/document/product/378/10740)
 - [Bind MFA device for login and operation](https://www.tencentcloud.com/document/product/378/32528)
 - [Manage a secure password](https://www.tencentcloud.com/document/product/378/14623)
 - [Create an administrator sub-user](https://www.tencentcloud.com/document/product/598/38247)
 - For the newly created sub-user, go to CAM -> User List -> “username” and [enable MFA](https://www.tencentcloud.com/document/product/378/32528). This is different account / device from the root user MFA
 - Make sure to follow [other best practices](https://www.tencentcloud.com/document/product/598/10592) for enhancing the security

## Deployment configuration
The deployment is made with terraform, directly through the API of the Tencent Cloud Account created in the step above. To achieve the deployment, the environment must be set-up. Here are the steps:

### Step1 - Generate new Tencent Cloud API keys and export them locally

**MacOS & Linux**
 - Create a new folder containing your project and switch to it 
      `mkdir $HOME/mvx-observer && cd "$_"`
 - Create a new environment variable file that will be used for sourcing (e.g `nano vars.txt`). This file should contain:
      `"TENCENTCLOUD_SECRET_ID": "",`
      `"TENCENTCLOUD_SECRET_KEY": "",`
      `"TENCENTCLOUD_REGION": ""`
   - The first 2 values you need to paste from the Tencent cloud console Access Key section and the region must be taken from the [valid list of regions](https://www.tencentcloud.com/document/product/416/6479?lang=en), for example `eu-frankfurt`
   - Once the 3 lines are added to the text file, save and close (**CTRL+X & Y** for nano)
   - Remember that this file contains the credentials to your Tencent Cloud Account, so it must be secured and not to be disclosed to unauthorized parties
 - source the file above to write the variables to current environment
      `source ~/Documents/Projects/export.txt` (example)
Once the environment variables are set you can continue to the next step

### Step2 - configure local deployment environment

 - [Install VSCode](https://code.visualstudio.com/)
 - Install VSCode Terraform extension
 - Open the terminal and Install terraform locally. For example on MacOS
     - `brew tap hashicorp/tap`
     - `brew install hashicorp/tap/terraform`
     - `terraform -version`

## Solution deployment

If you got up to this point, you are ready to deploy the solution.
For this you need to create a single file, which will contain the module instantiation with the custom parameters

Here is a sample

### Sample lite observer
```hcl
module "multiversx-observer-lite" {
  
#-------source repo
  source = "tencentcloud-tci/multiversx-node/tencentcloud" #terraform module published in the registry
  
  #-------basic variables
  az            = "eu-frankfurt-1" #availability zone to deploy
  instance_name = "mvx-myobserver" #name of the LH instance
  
  #-------deployment variables
  deployment_mode = "lite" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1 #the valability of the purchase, in months
  blueprint_id  = "lhbp-a7oxy3em" #the id of the blueprint, we recommend using OpenCloudOS8 with docker
  bundle_id = "bundle_ent_lin_02" #if performance is not a concern you can also use the 'bundle2022_gen_lin_05' (2core/8GB) for testnet/devnet only 
  
  #-------State specific variables
  need_tat_commands = true #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  
  #-------Chain specific variables
  network = "mainnet" #choose between mainnet, testnet, devnet
  
  #-------firewall details
  ssh_client_cidr = "2.222.22.2/32" #source ip of the management location (for SSH whitelisting)
  extra_firewall_rules = [{ #specify the public proxy port
    
      protocol                  = "TCP"
      port                      = "8079"
      cidr_block                = "0.0.0.0/0"
      action                    = "ACCEPT"
      firewall_rule_description = "proxy port"
    
  }]
}
```
### Sample db-lookup observer
```hcl
module "multiversx-observer" {
  
  #-------source repo
  source = "tencentcloud-tci/multiversx-node/tencentcloud" #terraform module published in the registry
  
  #-------basic variables
  az            = "eu-frankfurt-1" #availability zone to deploy
  instance_name = "mx-myobserver" #name of the LH instance
  
  #-------deployment variables
  deployment_mode = "lite" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1 #the valability of the purchase, in months
  blueprint_id  = "lhbp-a7oxy3em" #the id of the blueprint, we recommend using OpenCloudOS8 with docker
  bundle_id = "bundle_ent_lin_02" #if performance is not a concern you can also use the 'bundle2022_gen_lin_05' (2core/8GB) for testnet/devnet only 

  #-------State specific variables
  need_tat_commands = true #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  
  #-------Chain specific variables
  network = "mainnet" #choose between mainnet, testnet, devnet

  #-------firewall details
  ssh_client_cidr = "2.222.22.2/32" #source ip of the management location (for SSH whitelisting)
  extra_firewall_rules = [{ #specify the public proxy port
    
      protocol                  = "TCP"
      port                      = "8079"
      cidr_block                = "0.0.0.0/0"
      action                    = "ACCEPT"
      firewall_rule_description = "proxy port"
    
  }]
  #-------disk variables for db-lookup option
  #leave default unless disk becomes full
  cbs0_disk_size = 350 #disk contains node-0 and node-metachain data
  cbs1_disk_size = 450 #disk contains node-1
  cbs2_disk_size = 300 #disk contains node-2
  floating_cbs = "lhdisk-jkx4d2w4" #ID of the floater disk which will be used to download and extract the node DB history
}
```

### Main parameters
A few of parameters are needed to deploy the instance
 - `source` is the terraform registry module name
 - `az` is the availability zone within the selected region
 - `instance_name` give a name to your node
 - `purchase_period` the purchase period in months
 - `deployment_mode` the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
 - `bundle_id` used to select the instance type, leave default. [Other bundles](https://www.tencentcloud.com/document/product/1103/42472)
 - `blueprint_id` used for selection of the instance image, leave default. [Other blueprints](https://www.tencentcloud.com/document/product/1103/42503)
 - `ssh_client_cidr` source ip of the management location (for SSH whitelisting)
 - `need_tat_commands` set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
 - `network` choose between mainnet, testnet, devnet. This selection will switch the MultiversX network.
 - `floating_cbs` ID of the floater disk which will be used to download and extract the node DB history
 - `extra_firewall_rules` define own custom firewall inbound rule
 - `cbsX_disk_size` where X=0,1,2. this variable defines the size of the disk for the node databases
For reference here is the [Tencent Cloud Terraform provider](https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs/resources/lighthouse_instance)

### Stack deployment
Having the configuration done, continue with these commands
 - `terraform init`
 - `terraform plan`
 - `terraform apply` select yes, enter

The deployment will take more the for db-archive node types because of the node database which has to be retrieved from the mirror

If you are deploying in the same folder an updated version of the stack please upgrade the modules from source with the command below:
- `terraform init -upgrade`
More details [here](https://developer.hashicorp.com/terraform/cli/commands/init#upgrade)


## Deployment details

We use screen when start the different services. There are 5 screen sessions created:

* proxy
* squad-metachain
* squad-0
* squad-1
* squad-2

If you login the console hit `screen -r` to view the running screens and if you wish to enter one of the shard or proxy processes add its name at the end. For example `screen -r squad-1`
To exit the screen mode hit `CTRL-A + D`

Here are some details of the supported modes:
### Lite node type

| Program | Directory |
| -- | -- |
| node-0 | /data/MyObservingSquad/node-0 |
| node-1 | /data/MyObservingSquad/node-1 |
| node-2 | /data/MyObservingSquad/node-2 |
| node-metachain | /data/MyObservingSquad/node-metachain |
| proxy | /data/MyObservingSquad/proxy |


### DB-lookup node type
This node type requires an additional 3 cloud disks: cbs-0, cbs-1, cbs-2 plus one temporary disk 'cbs_float'

* cbs-0 containes the deployment of: node-0 and node-metachain
* cbs-1 containes the deployment of: node-1
* cbs-2 containes the deployment of: node-2
* cbs_float is a temporary disk, used to download the block database archives. By using these archive files, we can speed up the progress of synchronization during the initial deployment. When the node deployment is done, this temporary disk will be detached from the node.

| Service | Directory |
| -- | -- |
| node-0 | /data/MyObservingSquad/cbs-0/node-0 |
| node-1 | /data/MyObservingSquad/cbs-1/node-1 |
| node-2 | /data/MyObservingSquad/cbs-2/node-2 |
| node-metachain | /data/MyObservingSquad/cbs-0/node-metachain |
| proxy | /data/MyObservingSquad/proxy |

For the db-lookup option there are types of cloud disk available:

* hdd: corresponds to "premium cloud disks" on TencentCloud
* ssd: corresponds to "SSD cloud disks" on TencentCloud

Check the performance of these 2 cloud disk types [here](https://www.tencentcloud.com/document/product/362/31636)

## How to use the TAT commands
### multiversx-node-runner
This command is used to deploy a node. 

#### Parameters
`deployment_mode`
* required
* value: lite, db-lookup-hdd, db-lookup-ssd

when `deployment_mode=db-lookup-hdd, db-lookup-ssd`, extra variables should be set:

* `floating_cbs`: the temporary disk ID
* `deployment_mode`: has to be one of the 2 db-lookup options


### multiversx-node-tool
This command is for routine operations.

#### Parameters
`command`
* required
* value: upgrade_all, stop_all, start_all

| Value | Desc |
| -- | -- |
| `upgrade_all` | To check the docker image(multiversx/chain-observer, multiversx/chain-squad-proxy) latest tag. If there is a new tag, it will download and restart the node. |
| `stop_all` | To stop the node's programs |
| `start_all` | To start the node's programs |

# Managing the node

## Logging in
 - Log in Tencent Cloud Console and go to Lighthouse service 
 - Identify the instance and click log in -> Auto -> Login. you are now in the console

## Verify operation
 - Verify the node processes are running. You should see something like below
 ```bash
          [lighthouse@VM-0-24-centos ~]$ sudo -i
          [root@VM-0-24-centos ~]# docker ps
          CONTAINER ID   IMAGE                                COMMAND                  CREATED              STATUS              PORTS                                NAMES
          d99f497501cd   multiversx/chain-squad-proxy:using   "./proxy ./proxy"        About a minute ago   Up About a minute   8079-8080/tcp                        proxy
          1ade927d96e7   multiversx/chain-observer:using      "/go/mx-chain-go/cmd…"   About a minute ago   Up About a minute   8080/tcp, 0.0.0.0:10003->37373/tcp   squad-metachain
          c20f7bc91887   multiversx/chain-observer:using      "/go/mx-chain-go/cmd…"   About a minute ago   Up About a minute   8080/tcp, 0.0.0.0:10002->37373/tcp   squad-2
          51c1aa339df2   multiversx/chain-observer:using      "/go/mx-chain-go/cmd…"   About a minute ago   Up About a minute   8080/tcp, 0.0.0.0:10001->37373/tcp   squad-1
          30a5d0c28e48   multiversx/chain-observer:using      "/go/mx-chain-go/cmd…"   About a minute ago   Up About a minute   8080/tcp, 0.0.0.0:10000->37373/tcp   squad-0
          [root@VM-0-24-centos ~]# screen -r
          There are several suitable screens on:
               4481.proxy      (Detached)
               4420.squad-metachain    (Detached)
               4378.squad-2    (Detached)
               4357.squad-1    (Detached)
               4332.squad-0    (Detached)
          Type "screen [-d] -r [pid.]tty.host" to resume one of them.
          [root@VM-0-24-centos ~]# 
```
 - There are other, more advanced ways to verify node operation. Please check [MultiversX repository](https://github.com/multiversx/mx-chain-observing-squad)
 - Verify machine load and traffic by clicking the `Monitoring` tab
 

