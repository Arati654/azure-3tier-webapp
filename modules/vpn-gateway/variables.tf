variable "resource_group_name" {
  description = "The name of the Resource Group"
}

variable "location" {
  description = "Azure region where resources will be deployed"
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the existing Virtual Network"
}

variable "gateway_subnet_prefix" {
  type        = list(string)
  description = "Address prefix for the GatewaySubnet"
}

variable "vpn_gateway_name" {
  type        = string
  description = "Name of the VPN Gateway"
}

variable "vpn_sku" {
  type        = string
  description = "SKU for the VPN Gateway"
  default     = "VpnGw1"
}

