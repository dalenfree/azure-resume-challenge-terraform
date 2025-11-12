variable "location" {
  type    = string
  default = "canadacentral"
}

variable "customDomain" {
  type    = string
  default = "resume.dalenmcclintock.com"
  description = "full subdomain address for Front Door. E.g., 'cdn.example.com'."
}

variable "dnsDomain" {
  type    = string
  default = "dalenmcclintock"
  description = "The domain name without the TLD for DNS zone creation. E.g., 'example' for 'example.com'."
}

variable "dnsZone" {
  type    = string
  default = "dalenmcclintock.com"
  description = "The DNS zone domain for DNS zone creation. E.g., 'example.com'."
}

variable "resourceGroupName" {
  type    = string
  default = "tfresumerg"
}

variable "cosmos_db_database_name" {
  type    = string
  default = "Counter"
}

variable "cosmos_db_container_name" {
  type    = string
  default = "Visitors"
}