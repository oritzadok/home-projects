output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "kubernetes_cluster" {
  value = azurerm_kubernetes_cluster.cluster.name
}

output "kubernetes_namespace" {
  value = var.k8s_namespace
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "acr_url" {
  value = azurerm_container_registry.acr.login_server
}

output "service_bus_namespace" {
  value = azurerm_servicebus_namespace.sb.name
}

output "service_bus_queue" {
  value = azurerm_servicebus_queue.q.name
}

output "storage_account" {
  value = azurerm_storage_account.sa.name
}

output "storage_account_container" {
  value = azurerm_storage_container.c.name
}

output "consumer_managed_identity" {
  value = azurerm_user_assigned_identity.consumer.client_id
}

output "keda_managed_identity" {
  value = azurerm_user_assigned_identity.keda.client_id
}