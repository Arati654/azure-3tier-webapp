variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
}

variable "sql_server_name" {
  type        = string
  description = "SQL server name"
}

variable "sql_admin_username" {
  type        = string
  description = "SQL admin username"
}

variable "sql_password" {
  type        = string
  description = "SQL admin password"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_edition" {
  type        = string
  default     = "Standard"
  description = "Database edition"
}

variable "service_objective_name" {
  type        = string
  default     = "S1"
  description = "Service objective (S0, S1, etc.)"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags for resources"
}

variable "firewall_rules" {
  type = list(object({
    name      = string
    start_ip  = string
    end_ip    = string
  }))
  default     = []
  description = "SQL firewall rules"
}
