# MultiversX Terraform Stack for Observer

This solution deploys a Terraform stack for the MultiversX observer nodes on Tencent Cloud. The solution uses Tencent Cloud Lighthouse as main compute service.

Multiversx documentation: https://github.com/multiversx/mx-chain-observing-squad#observing-squad

## Usage
```hcl
module "observer" {
  source        = "git@github.com:ritch2022/terraform-tencentcloud-multiversx-lighthouse.git"

  az            = "eu-frankfurt-1"

  instance_name = "mx-light"
  deployment_mode = "squad"
  observer_type   = "lite"
  purchase_period = 1
}
```

## Setting the LightHouse instance
Two main parameters are needed to deploy the instance
 - `bundle_id` used to select the instance type,
 - `blueprint_id` used for selection of the instance image. 

Other optional values can be further reviewed below:
* https://www.tencentcloud.com/document/product/1103/42472
* https://www.tencentcloud.com/document/product/1103/42503

The terraform input variables, are found in the page below:
* https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs/resources/lighthouse_instance


## Deployment details

First of all, edit the file `/data/MyObservingSquad/observer_type` in order to select the observer type of the deployment.

For example:
```
db-lookup
```
Here are the supported modes:
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

| Program | Directory |
| -- | -- |
| node-0 | /data/MyObservingSquad/cbs-0/node-0 |
| node-1 | /data/MyObservingSquad/cbs-1/node-1 |
| node-2 | /data/MyObservingSquad/cbs-2/node-2 |
| node-metachain | /data/MyObservingSquad/cbs-0/node-metachain |
| proxy | /data/MyObservingSquad/proxy |

## How to use TAT commands
### multiversx-node-runner
This command is used to deploy a node. 

#### Parameters
`observer_type`
* required
* value: lite, db-lookup

when `observer_type=db-lookup`, extra parameters should be set:

* `lighthouse_id`: the lighthouse instance id, like: lhins-q45lxxxx
* `cbs_0`: the cloud disk for node-0 and node-metachain
* `cbs_1`: the cloud disk for node-1
* `cbs_2`: the cloud disk for node-2
* `cbs_float`: the cloud disk for store the blocks database files
* `secret_id`: secret_id
* `secret_key`: secret_key

### multiversx-node-tool
This command is for daily operation.

#### Parameters
`command`
* required
* value: upgrade_all, stop_all, start_all, destroy

| Value | Desc |
| -- | -- |
| `upgrade_all` | To check the docker image(multiversx/chain-observer, multiversx/chain-squad-proxy) latest tag. If there is a new tag, it will download and restart the node. |
| `stop_all` | To stop the node's programs |
| `start_all` | To start the node's programs |
| `destroy` | To stop the node's programs, umount the working directory(for db-lookup observer type) and remove it |
