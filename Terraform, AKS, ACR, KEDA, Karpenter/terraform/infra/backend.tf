resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
}


resource "azurerm_container_registry" "acr" {
  name                = var.resource_group_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}


resource "azurerm_servicebus_namespace" "sb" {
  name                = "${var.resource_group_name}ServiceBus"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
}


resource "azurerm_servicebus_queue" "q" {
  name         = "myqueue"
  namespace_id = azurerm_servicebus_namespace.sb.id
}


resource "azurerm_storage_account" "sa" {
  name                            = var.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  account_tier                    = "Standard"
  account_replication_type        = "RAGRS"
  allow_nested_items_to_be_public = false
  large_file_share_enabled        = true
}


resource "azurerm_storage_container" "c" {
  name                  = "messages"
  storage_account_id    = azurerm_storage_account.sa.id
}