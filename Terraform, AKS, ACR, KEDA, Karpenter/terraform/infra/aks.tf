resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.resource_group_name}Cluster"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.resource_group_name}Cluster-dns"

  default_node_pool {
    name       = "agentpool"
    node_count = 3
    vm_size    = "Standard_DS2_v2"

    upgrade_settings {
      max_surge= "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
    network_plugin_mode = "overlay"
  }

  node_provisioning_profile {
    # Karpenter
    default_node_pools = "Auto"
    mode               = "Auto"
  }

  workload_autoscaler_profile {
    keda_enabled = true
  }

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  image_cleaner_enabled        = true
  image_cleaner_interval_hours = 168

  maintenance_window_node_os {
    day_of_month = 0
    day_of_week  = "Sunday"
    duration     = 8
    frequency    = "Weekly"
    interval     = 1
    start_time   = "00:00"
    utc_offset   = "+00:00"
  }
}


resource "azurerm_role_assignment" "aks_AcrPull" {
  principal_id         = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}


resource "azurerm_user_assigned_identity" "keda" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${azurerm_kubernetes_cluster.cluster.name}-KEDA"
}


resource "azurerm_federated_identity_credential" "keda" {
  name                = "${azurerm_kubernetes_cluster.cluster.name}-KEDA"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.keda.id
  subject             = "system:serviceaccount:kube-system:keda-operator"
}


# After creating the federated credential for the keda-operator ServiceAccount,
# the keda-operator pods need to be restarted to ensure Workload Identity environment variables are injected into the pod.
# https://learn.microsoft.com/he-il/azure/aks/keda-workload-identity#enable-workload-identity-on-keda-operator
resource "null_resource" "restart_keda_operator" {
  provisioner "local-exec" {
    command = "./files/restart_keda_operator.sh ${azurerm_resource_group.rg.name} ${azurerm_kubernetes_cluster.cluster.name}"
  }

  depends_on = [
    azurerm_federated_identity_credential.keda
  ]
}


resource "azurerm_role_assignment" "keda_roles" {
  for_each = {
    "servicebus1" = { role = "Azure Service Bus Data Owner", scope = azurerm_servicebus_namespace.sb.id }
  }
  principal_id         = azurerm_user_assigned_identity.keda.principal_id
  role_definition_name = each.value.role
  scope                = each.value.scope
}


resource "azurerm_user_assigned_identity" "consumer" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${azurerm_kubernetes_cluster.cluster.name}-Consumer"
}


resource "azurerm_federated_identity_credential" "consumer" {
  name                = "${azurerm_kubernetes_cluster.cluster.name}-Consumer"
  resource_group_name = azurerm_resource_group.rg.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.cluster.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.consumer.id
  subject             = "system:serviceaccount:${var.k8s_namespace}:consumer"
}


resource "azurerm_role_assignment" "consumer_roles" {
  for_each = {
    "servicebus1"    = { role = "Azure Service Bus Data Owner", scope = azurerm_servicebus_namespace.sb.id }
    "storageaccount1" = { role = "Storage Blob Data Contributor", scope = azurerm_storage_account.sa.id }
  }
  principal_id         = azurerm_user_assigned_identity.consumer.principal_id
  role_definition_name = each.value.role
  scope                = each.value.scope
}