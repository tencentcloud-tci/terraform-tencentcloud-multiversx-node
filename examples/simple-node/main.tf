module "multiversx-observer" {
  #source            = "ritch2022/multiversx-lighthouse/tencentcloud" #terraform module published in the registry
  #version           = "0.2.5"                                        #version of the terraform  module in the registry
  source = "/Users/tudortoma/Documents/terraform-tencentcloud-multiversx-lighthouse"
  
  az                = "eu-frankfurt-1"                               #availability zone to deploy
  instance_name     = "mx-test"                                #name of the LH instance
  deployment_mode   = "lite"                                         #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period   = 1                                              #the valability of the purchase, in months
  ssh_client_cidr   = "2.222.22.2/32"                                #source ip of the management location (for SSH whitelisting)
  need_tat_commands = true                                           #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  extra_firewall_rules = [{ #specify the public proxy port

    protocol                  = "TCP"
    port                      = "8079"
    cidr_block                = "0.0.0.0/0"
    action                    = "ACCEPT"
    firewall_rule_description = "proxy port"

  }]
  #-------disk variables for db-lookup option
  #leave default unless disk becomes full
  #node0_disk_size = 250 #disk contains node-0 and node-metachain data
  #node1_disk_size = 350 #disk contains node-1
  #node2_disk_size = 200 #disk contains node-2
  #floating_cbs = "lhdisk-jkx4d2w4" #ID of the floater disk which will be used to download and extract the node DB history
}