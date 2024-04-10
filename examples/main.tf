module "multiversx-observer" {

  #-------source repo
  source = "tencentcloud-tci/multiversx-node/tencentcloud" #terraform module published in the registry

  #-------basic variables
  az            = "eu-frankfurt-2"    #availability zone to deploy. Feel free to change the region and availability zone. More info here: https://www.tencentcloud.com/document/product/213/6091 and here: https://www.tencentcloud.com/document/product/1103/41266
  instance_name = "mvx-observer-test" #name of the LH instance
  blueprint_id  = "lhbp-a7oxy3em"
  bundle_id     = "bundle_ent_lin_02" #if performance is not a concern you can also use the 'bundle2022_gen_lin_05' (2core/8GB) for testnet/devnet only 
  #for more information please refer to MultiversX system requirements: https://docs.multiversx.com/validators/system-requirements

  #-------deployment variables
  deployment_mode = "db-lookup-hdd" #the deployment mode: lite, db-lookup-hdd, db-lookup-ssd
  purchase_period = 1               #the valability of the purchase, in months

  #-------State specific variables
  need_tat_commands = true     #set 'false' only if the commands are already deployed (if previous/paralel deployment existed)
  network           = "mainnet" #choose between mainnet, testnet, devnet

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
  #here are some current (April 2024) recommended values for each network, if you consider a month of running the node
  #nevertheless, before spinning up your node, please consult MultiversX recommended shard blocks database size 
  #1 month estimates below
  #---------------------------------------------------------------
  #devnet (estimated 10-20GB per shard per month)
  #   - CBS0: min.20GB, safe.40GB
  #   - CBS1: min.10GB, safe.20GB
  #   - CBS2: min.10GB, safe.20GB
  #---------------------------------------------------------------
  #testnet (estimated 10-20GB per shard per month)
  #   - CBS0: min.20GB, safe.40GB
  #   - CBS1: min.10GB, safe.20GB
  #   - CBS2: min.10GB, safe.20GB
  #---------------------------------------------------------------
  #mainnet (estimated 10-50GB per shard per month)
  #   - CBS0: min.400GB, safe.500GB
  #   - CBS1: min.500GB, safe.600GB
  #   - CBS2: min.300GB, safe.400GB

  cbs0_disk_size = 50                #disk contains node-0 and node-metachain data
  cbs1_disk_size = 50                #disk contains node-1
  cbs2_disk_size = 50                #disk contains node-2
}