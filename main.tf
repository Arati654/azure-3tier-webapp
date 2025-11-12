terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
       version = "~> 4.38"
    }
  }
  required_version = ">= 1.3.0"
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstateaccountarati"
    container_name       = "tfstate"
    key                  = "infra.terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "8984a10f-891b-4126-83f7-3629bb34f22c"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  
}
resource "azurerm_resource_group" "rgname" {
  name     = var.rg_name
  location = var.location
}

//module to create vnet
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "5.0.0"
  # insert the 3 required variables here
  resource_group_name = azurerm_resource_group.rgname.name
  vnet_location       = azurerm_resource_group.rgname.location
  vnet_name           = "EnterpriseVnet"
  address_space       = ["10.0.0.0/16"]
  use_for_each        = false

  subnet_names    = ["web", "app", "data"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

}

module "web_nsg" {
  source              = "./modules/nsg"
  nsg_name            = "web-nsg"
  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  subnet_id           = module.vnet.vnet_subnets[0]

  rules = [
    {
      name                       = "allow_http"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "80"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    },
    {
      name                       = "allow_https"
      priority                   = 110
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "*"
      destination_address_prefix = "*"
    }
  ]
}

module "app_nsg" {
  source              = "./modules/nsg"
  nsg_name            = "app-nsg"
  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  subnet_id           = module.vnet.vnet_subnets[1]

  rules = [
    {
      name                       = "allow_web_to_app"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "8080"
      source_address_prefix      = "10.0.1.0/24" # Web subnet
      destination_address_prefix = "*"
    }
  ]  
}

module "data_nsg" {
  source              = "./modules/nsg"
  nsg_name            = "data-nsg"
  location            = azurerm_resource_group.rgname.location
  resource_group_name = azurerm_resource_group.rgname.name
  subnet_id           = module.vnet.vnet_subnets[2]

  rules = [
    {
      name                       = "allow_app_to_db"
      priority                   = 100
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "1433"
      source_address_prefix      = "10.0.2.0/24" # App subnet
      destination_address_prefix = "*"
    }
      
  ]
}

module "vpn_gateway" {
  source = "./modules/vpn-gateway"

  resource_group_name   = azurerm_resource_group.rgname.name
  location              = azurerm_resource_group.rgname.location
  virtual_network_name  = module.vnet.vnet_name
  gateway_subnet_prefix = ["10.0.255.0/27"]
  vpn_gateway_name      = "my-vpn-gateway"
  vpn_sku               = "VpnGw1"

  depends_on = [module.vnet]
}

module "web_lb" {
  source  = "Azure/loadbalancer/azurerm"
  version = "4.4.0"

  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  prefix              = "web-lb"
  lb_sku              = "Standard"
  type                = "public"
  frontend_name       = "web-frontend"
  
  # Leave pip_name empty to auto-create
  pip_name            = ""
  pip_sku = "Standard"
  
 lb_port = {
    http = [80, "Tcp", 80]  # map of lists, not objects
  }
  
  lb_probe = {
    http = ["Http", 80, "/"]  # map of lists, not objects
  }

  lb_probe_interval           = 5
  lb_probe_unhealthy_threshold = 2

  tags = { project = "EnterpriseWebApp"}

  depends_on = [azurerm_resource_group.rgname]
}

module "app-service" {
  source  = "claranet/app-service/azurerm"
  version = "8.3.1"
   client_name           = "arati"
   environment           = "dev"
  location              = azurerm_resource_group.rgname.location
  location_short        = var.location_short
  logs_destinations_ids = []
  os_type               = "Linux"
  resource_group_name   = azurerm_resource_group.rgname.name
  sku_name              = "S1"  
  stack                 = "web"
  zone_balancing_enabled  = false
  application_insights = {
    enabled                   = false
    log_analytics_workspace_id =  null
    }

   app_settings = {
     DATABASE_CONNECTION_STRING = module.database.connection_string
   }
   depends_on = [
    azurerm_log_analytics_workspace.law,
    module.database,
    module.web_lb
  ]

  extra_tags = {
    project = "EnterpriseWebApp"
    }
}

module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.rgname.name
  location            = azurerm_resource_group.rgname.location
  sql_server_name     = "ecommerce-sqlsrv"
  sql_admin_username  = "sqladminuser"
  sql_password        = "ComplexP@ssw0rd123!"  # in production, use Key Vault
  db_name             = "ecommerce-db"
  db_edition          = "Standard"
  service_objective_name = "S1"
  tags = {
    project     = "EnterpriseWebApp"
    environment = "dev"
  }
  firewall_rules = [
    {
      name     = "app-subnet"
      start_ip = "10.0.2.0"
      end_ip   = "10.0.2.255"
    }
  ]
}


resource "azurerm_mssql_database" "secondary" {
  name                = "ecommerce-db-secondary"
  create_mode         = "Secondary"
  creation_source_database_id = module.database.sql_database_id
  server_id           = module.database.sql_server_id
}


resource "azurerm_storage_account" "static" {
  name                     = "aratistaticwebacc"
  resource_group_name      = azurerm_resource_group.rgname.name
  location                 = azurerm_resource_group.rgname.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = { project = "EnterpriseWebApp" }
}

resource "azurerm_storage_account_static_website" "static_site" {
  storage_account_id = azurerm_storage_account.static.id
  index_document     = "index.html"
  error_404_document = "404.html"
}


resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-ecom-arati"
  location            = azurerm_resource_group.rgname.location
  resource_group_name = azurerm_resource_group.rgname.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "ai" {
  name                = "ai-ecom-arati"
  location            = azurerm_resource_group.rgname.location
  resource_group_name = azurerm_resource_group.rgname.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.law.id
}