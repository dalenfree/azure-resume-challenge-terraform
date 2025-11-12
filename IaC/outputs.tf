output "cdn_frontdoor_endpoint_hostname" {
  description = "The hostname of the CDN Front Door endpoint."
  value       = azurerm_cdn_frontdoor_endpoint.cdn_frontdoor_endpoint.host_name
  sensitive = true
}   

output "cosmos_db_url" {
  description = "The endpoint URL of the Cosmos DB account."
  value       = azurerm_cosmosdb_account.cosmos_db_account.endpoint
}
