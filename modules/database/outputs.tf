output "sql_server_id" {
  value = azurerm_mssql_server.this.id
}

output "sql_server_name" {
  value = azurerm_mssql_server.this.name
}

output "sql_server_fqdn" {
  value = azurerm_mssql_server.this.fully_qualified_domain_name
}

output "sql_database_id" {
  value = azurerm_mssql_database.this.id
}

output "connection_string" {
  value = "Server=tcp:${azurerm_mssql_server.this.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.this.name};User ID=${var.sql_admin_username};Password=${var.sql_password};Encrypt=true;Connection Timeout=30;"
  sensitive = true
}
