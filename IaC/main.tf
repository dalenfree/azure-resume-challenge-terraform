# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.52.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "resource_group" {
  name     = var.resourceGroupName
  location = var.location
}

resource "random_integer" "resource_group_suffix" {
  min = 10000
  max = 99999

  keepers = {
    resource_group_id = azurerm_resource_group.resource_group.id
  }
}

# Create a Storage Account and Blob Container for Frontend
resource "azurerm_storage_account" "frontend_storage_account" {
  name                     = "frontend${random_integer.resource_group_suffix.result}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_account_static_website" "storage_account_static_website" {
  storage_account_id = azurerm_storage_account.frontend_storage_account.id
  index_document    = "index.html"
  error_404_document = "404.html"
}

# Create a Function App with Python Runtime
resource "azurerm_storage_account" "function_app_storage_account" {
  name                     = "fasa${random_integer.resource_group_suffix.result}"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "function_app_storage_container" {
  name                  = "facontainer${random_integer.resource_group_suffix.result}"
  storage_account_id    = azurerm_storage_account.function_app_storage_account.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "function_app_service_plan" {
  name                = "fasplan${random_integer.resource_group_suffix.result}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku_name            = "FC1"
  os_type             = "Linux"
}

resource "azurerm_function_app_flex_consumption" "function_app" {
  name                = "fa${random_integer.resource_group_suffix.result}"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  service_plan_id     = azurerm_service_plan.function_app_service_plan.id
  

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.function_app_storage_account.primary_blob_endpoint}${azurerm_storage_container.function_app_storage_container.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.function_app_storage_account.primary_access_key
  runtime_name                = "python"
  runtime_version             = "3.11"
  maximum_instance_count      = 50
  instance_memory_in_mb       = 2048
  identity {type = "SystemAssigned"}

  site_config {
    application_insights_connection_string = azurerm_application_insights.frontdoor_app_insights.connection_string
    application_insights_key = azurerm_application_insights.frontdoor_app_insights.instrumentation_key  
  }
}

resource "azurerm_application_insights" "frontdoor_app_insights" {
  name                = "fdappinsights${random_integer.resource_group_suffix.result}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "web"
}

output "instrumentation_key" {
  value = azurerm_application_insights.frontdoor_app_insights.instrumentation_key
  sensitive = true
}

output "app_id" {
  value = azurerm_application_insights.frontdoor_app_insights.app_id
  sensitive = true
}

# Create a Cosmos DB Account, SQL Database, and Container
resource "azurerm_cosmosdb_account" "cosmos_db_account" {
  name                = "cdb${random_integer.resource_group_suffix.result}"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  consistency_policy {
    consistency_level = "Session"
  }
  geo_location {
    location          = azurerm_resource_group.resource_group.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "cosmos_db_sql_database" {
  name                = var.cosmos_db_database_name
  resource_group_name = azurerm_resource_group.resource_group.name
  account_name        = azurerm_cosmosdb_account.cosmos_db_account.name
}

resource "azurerm_cosmosdb_sql_container" "cosmos_db_sql_container" {
  name                  = var.cosmos_db_container_name
  resource_group_name   = azurerm_resource_group.resource_group.name
  account_name          = azurerm_cosmosdb_account.cosmos_db_account.name
  database_name         = azurerm_cosmosdb_sql_database.cosmos_db_sql_database.name
  partition_key_paths   = ["/id"]
  partition_key_version = 1
  throughput            = 400

  indexing_policy {
    indexing_mode = "consistent"

    included_path {
      path = "/*"
    }

    included_path {
      path = "/included/?"
    }

    excluded_path {
      path = "/excluded/?"
    }
  }

  unique_key {
    paths = ["/definition/idlong", "/definition/idshort"]
  }
}

# Front Door configuration with Custom Domain and DNS Records
resource "azurerm_cdn_frontdoor_profile" "cdn_frontdoor_profile" {
  name                = "fdprofile${random_integer.resource_group_suffix.result}"
  resource_group_name = azurerm_resource_group.resource_group.name
  sku_name            = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_origin_group" "cdn_frontdoor_origin_group" {
  name                     = "fdorigingroup${random_integer.resource_group_suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_frontdoor_profile.id

  load_balancing {
    additional_latency_in_milliseconds = 0
    sample_size                        = 16
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "cdn_frontdoor_origin" {
  name                          = "fdorigin${random_integer.resource_group_suffix.result}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.cdn_frontdoor_origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false

  host_name          = var.dnsZone
  http_port          = 80
  https_port         = 443
  origin_host_header = var.customDomain
  priority           = 1
  weight             = 1
}

resource "azurerm_cdn_frontdoor_endpoint" "cdn_frontdoor_endpoint" {
  name                     = "fdendpoint${random_integer.resource_group_suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_frontdoor_profile.id
}

resource "azurerm_cdn_frontdoor_rule_set" "cdn_frontdoor_rule_set" {
  name                     = "fdruleset${random_integer.resource_group_suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_frontdoor_profile.id
}

resource "azurerm_cdn_frontdoor_route" "cdn_frontdoor_route" {
  name                          = "fdroute${random_integer.resource_group_suffix.result}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.cdn_frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.cdn_frontdoor_origin_group.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.cdn_frontdoor_origin.id]
  cdn_frontdoor_rule_set_ids    = [azurerm_cdn_frontdoor_rule_set.cdn_frontdoor_rule_set.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {
    query_string_caching_behavior = "IgnoreSpecifiedQueryStrings"
    query_strings                 = ["account", "settings"]
    compression_enabled           = true
    content_types_to_compress     = ["text/html", "text/javascript", "text/xml"]
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "cdn_frontdoor_custom_domain" {
  name                     = "fdcustomdomain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.cdn_frontdoor_profile.id
  host_name                = var.customDomain

  tls {
    certificate_type    = "ManagedCertificate"
  }
}