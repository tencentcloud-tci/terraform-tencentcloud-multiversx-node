module "multiversx-observer" {

  #-------source repo
  #source = "tencentcloud-tci/multiversx-node/tencentcloud" #terraform module published in the registry
  source = "/Users/tudortoma/Documents/Projects/terraform-tencentcloud-multiversx-node" #terraform module published in the registry

  #-------basic variables
  az            = "eu-frankfurt-2"    #availability zone to deploy
  instance_name = "mvx-observer-test" #name of the LH instance
  blueprint_id  = "lhbp-a7oxy3em"
  bundle_id     = "bundle_ent_lin_02" #if performance is not a concern you can also use the 'bundle2022_gen_lin_05' (2core/8GB) for testnet/devnet only 
  #for more information please refer to MultiversX system requirements: https://docs.multiversx.com/validators/system-requirements

  #-------deployment variables
  deployment_mode = "db-lookup-hdd" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1               #the valability of the purchase, in months

  #-------State specific variables
  need_tat_commands = true     #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  network           = "devnet" #choose between mainnet, testnet, devnet

  #-------firewall details
  ssh_client_cidr = "2.222.22.2/32" #source ip of the management location (for SSH whitelisting)
  extra_firewall_rules = [{         #specify the public proxy port

    protocol                  = "TCP"
    port                      = "8079"
    cidr_block                = "0.0.0.0/0"
    action                    = "ACCEPT"
    firewall_rule_description = "proxy port"

  }]
  #-------disk variables for db-lookup option
  #leave default unless disk becomes full
  cbs0_disk_size = 50                #disk contains node-0 and node-metachain data
  cbs1_disk_size = 50                #disk contains node-1
  cbs2_disk_size = 50                #disk contains node-2
  floating_cbs   = "lhdisk-dzxbu4z2" #ID of the floater disk which will be used to download and extract the node DB history
}