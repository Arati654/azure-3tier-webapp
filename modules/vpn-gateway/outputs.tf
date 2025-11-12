output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.vpn_gateway.id
}

output "public_ip_address" {
  value = azurerm_public_ip.vpn_gateway_ip.ip_address
}
