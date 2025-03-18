# Definition of the provider we will use
provider "azurerm" {
  features {}
  subscription_id = ""
}

# The resource group is created, to which the other resources will be associated
resource "azurerm_resource_group" "rg" {
  name     = var.name_function
  location = var.location
}

# A Storage Account is created to associate it with the Function App (as recommended by the documentation).
resource "azurerm_storage_account" "sa" {
  name                     = var.name_function
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# The Service Plan resource is created to specify the service level 
# (e.g., "Consumption", "Functions Premium", or "App Service Plan"), in this case, "Y1" refers to the Consumption plan.
resource "azurerm_service_plan" "sp" {
  name                = var.name_function
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

# The Function App is created
resource "azurerm_windows_function_app" "wfa" {
  name                = var.name_function
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  service_plan_id            = azurerm_service_plan.sp.id

  site_config {
    application_stack {
      node_version = "~18"
    }
  }
}

# A function is created within the Function App
resource "azurerm_function_app_function" "faf" {
  name            = var.name_function
  function_app_id = azurerm_windows_function_app.wfa.id
  language        = "Javascript"
  # Example code is loaded into the function
  file {
    name    = "index.js"
    content = file("example/index.js")
  }
  # Test payload is defined
  test_data = jsonencode({
    "name" = "Azure"
  })
  # Requests are mapped
  config_json = jsonencode({
    "bindings" : [
      {
        "authLevel" : "anonymous",
        "type" : "httpTrigger",
        "direction" : "in",
        "name" : "req",
        "methods" : [
          "get",
          "post"
        ]
      },
      {
        "type" : "http",
        "direction" : "out",
        "name" : "res"
      }
    ]
  })
}