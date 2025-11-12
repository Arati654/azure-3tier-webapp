resource "azurerm_mssql_server" "this" {
  name                         = var.sql_server_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_username
  administrator_login_password  = var.sql_password
  tags                          = var.tags
}

resource "azurerm_mssql_database" "this" {
  name       = var.db_name
  server_id  = azurerm_mssql_server.this.id
  sku_name   = "S1"
  tags       = var.tags
}

resource "azurerm_mssql_firewall_rule" "this" {
  for_each  = { for rule in var.firewall_rules : rule.name => rule }
  name      = each.value.name
  server_id = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}
