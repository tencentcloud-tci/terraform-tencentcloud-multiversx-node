# Tencentcloud MultiversX Terraform Module

Terraform module which deploys a MultiversX observer node on Tencentcloud. It uses lighthouse.

Multiversx doc: https://github.com/multiversx/mx-chain-observing-squad#verify-the-running-containers

## Usage
```hcl
module "observer" {
  source        = "./modules/multiversx-observer"

  az            = "eu-frankfurt-1"

  instance_name = "mx-light"
  deployment_mode = "squad"
  observer_type   = "lite"
  purchase_period = 1
}
```

## Setting LightHouse instance
`bundle_id` is for instance type, and `blueprint_id` is for instance image. 

The optional values can be refered to here:
* https://www.tencentcloud.com/document/product/1103/42472
* https://www.tencentcloud.com/document/product/1103/42503

For other input variables, you can refer to:
* https://registry.terraform.io/providers/tencentcloudstack/tencentcloud/latest/docs/resources/lighthouse_instance


## Deployment details
Configure file `/data/MyObservingSquad/observer_type` records the observer type of the current deployment.

For example:
```
standard
```

### Lite node

| Program | Directory |
| -- | -- |
| node-0 | /data/MyObservingSquad/node-0 |
| node-1 | /data/MyObservingSquad/node-1 |
| node-2 | /data/MyObservingSquad/node-2 |
| node-metachain | /data/MyObservingSquad/node-metachain |
| proxy | /data/MyObservingSquad/proxy |


### Standard node
We introduce 3 cloud disks: cbs-0, cbs-1, cbs-2 and cbs_float

* cbs-0 deploys node-0 and node-metachain
* cbs-1 deploys node-1
* cbs-2 deploys node-2
* cbs_float is used to download the db files. By using db files, we can speed up the progress of synchronization during the fist-time deployment. When the deployment is done, it will be detached.

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
* value: lite, standard

when `observer_type=standard`, extra parameters should be set:

* `lighthouse_id`: the lighthouse instance id, like: lhins-q45lxxxx
* `cbs_0`: the cloud disk for node-0 and node-metachain
* `cbs_1`: the cloud disk for node-1
* `cbs_2`: the cloud disk for node-2
* `cbs_float`: the cloud disk for store db files
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
| `destroy` | To stop the node's programs, umount the working directory(for standard observer type) and remove it |
