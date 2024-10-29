resource "azurerm_user_assigned_identity" "databricks_identity" {
  name                = "databricks-identity"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_role_assignment" "blob_data_contributor" {
  principal_id   = azurerm_user_assigned_identity.databricks_identity.principal_id
  scope          = azurerm_storage_account.blob_storage.id
  role_definition_name = "Storage Blob Data Contributor"
}