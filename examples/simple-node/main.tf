module "multiversx-observer" {
  source  = "ritch2022/multiversx-lighthouse/tencentcloud" #terraform module published in the registry
  version = "0.2.2" #version of the terraform  module in the registry
  az            = "eu-frankfurt-1" #availability zone to deploy
  instance_name = "mx-myobserver" #name of the LH instance
  deployment_mode = "lite" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1 #the valability of the purchase, in months
  ssh_client_cidr = "2.222.22.2/32" #source ip of the management location (for SSH whitelisting)
  need_tat_commands = true #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  #floating_cbs = "lhdisk-jkx4d2w4"
  extra_firewall_rules = [{ #specify the public proxy port
    
      protocol                  = "TCP"
      port                      = "8079"
      cidr_block                = "0.0.0.0/0"
      action                    = "ACCEPT"
      firewall_rule_description = "proxy port"
    
  }]
}