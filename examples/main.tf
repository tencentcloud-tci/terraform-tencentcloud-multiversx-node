module "multiversx-observer" {

  #-------source repo
  #source = "tencentcloud-tci/multiversx-node/tencentcloud" #terraform module published in the registry
  source = "/Users/tudortoma/Documents/Projects/terraform-tencentcloud-multiversx-node"
  #-------basic variables
  az            = "eu-frankfurt-1"       #availability zone to deploy
  instance_name = "mvx-observer-testnet" #name of the LH instance
  blueprint_id  = "lhbp-a7oxy3em"

  #-------deployment variables
  deployment_mode = "db-lookup-hdd" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1               #the valability of the purchase, in months

  #-------State specific variables
  need_tat_commands = false     #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  network           = "testnet" #choose between mainnet, testnet, devnet

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
  floating_cbs   = "lhdisk-c0wn1l0m" #ID of the floater disk which will be used to download and extract the node DB history
}