variable "rg_name" {
  description = "The name of the resource group"
  type        = string
  default = "rg-enterprise-app"
}

variable "location" {
  description = "The location of the resource group"
  default = "canadacentral"

}

variable "location_short" {
 description = "Name of the Location in short form"
  default = "ccan"
  
}