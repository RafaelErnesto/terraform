
resource "azurerm_resource_group" "gallery_service" {
 name     = local.namespace
 location = var.location
}

resource "azurerm_storage_account" "gallery_service_storage_account" {
 name                     = random_string.rand.result
 resource_group_name      = azurerm_resource_group.gallery_service.name
 location                 = azurerm_resource_group.gallery_service.location
 account_tier             = "Standard"
 account_replication_type = "LRS"
}

resource "azurerm_storage_container" "storage_container" {
 name                  = "gallery-service-container"
 storage_account_name  = azurerm_storage_account.gallery_service_storage_account.name
 container_access_type = "private"
}