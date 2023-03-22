
resource "azurerm_resource_group" "gallery-service" {
 name     = local.namespace
 location = var.location
}