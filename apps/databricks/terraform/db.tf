resource "azurerm_databricks_workspace" "mmed-workspaces" {
  name                       = "mmed"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.region
  sku                        = "trial"
  managed_resource_group_name = azurerm_resource_group.this.name
  tags = merge(
    local.tags,
    {
      Division = "mmed"
    }
  )
  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = azurerm_virtual_network.this.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }
}

resource "azurerm_databricks_workspace" "eetd-workspaces" {
  name                       = "eetd"
  resource_group_name        = azurerm_resource_group.this.name
  location                   = var.region
  sku                        = "trial"
  managed_resource_group_name = azurerm_resource_group.this.name
  tags = merge(
    local.tags,
    {
      Division = "eetd"
    }
  )
  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = azurerm_virtual_network.this.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }
}

resource "azurerm_resource_group" "this" {
  name     = "${local.prefix}-rg"
  location = var.region
  tags = merge(
    local.tags,
  )
}

resource "databricks_storage_credential" "storage_credential" {
  name = "my_blob_storage_credential"

  azurerm_managed_identity {
    client_id = azurerm_user_assigned_identity.databricks_identity.client_id
  }
}

resource "databricks_external_location" "external_location" {
  name                    = "my_blob_external_location"
  storage_credential_name = databricks_storage_credential.storage_credential.name
  url                     = "wasbs://${azurerm_storage_container.blob_container.name}@${azurerm_storage_account.blob_storage.name}.blob.core.windows.net/"
  comment                 = "External location for flat files in Azure Blob Storage"
}

resource "databricks_catalog" "scientific" {
  name    = "scientific"
  comment = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}

resource "databricks_schema" "things" {
  catalog_name = databricks_catalog.scientific.name
  name         = "things"
  comment      = "this schema is managed by terraform"
  properties = {
    kind = "various"
  }
}

resource "databricks_external_location" "some" {
	name                    = "some_external_location"
	storage_credential_name = databricks_storage_credential.storage_credential.name
	url                     = format("wasbs://%s@%s.blob.core.windows.net/",
		azurerm_storage_container.some_container.name,
		azurerm_storage_account.blob_storage.name
	comment                 = "External location for scientific files"
}

resource "databricks_external_location" "some" {
  name = "external"
  url = format("abfss://%s@%s.dfs.core.windows.net",
    azurerm_storage_container.ext_storage.name,
  azurerm_storage_account.ext_storage.name)
  credential_name = databricks_storage_credential.external.id
  comment         = "Managed by TF"
  depends_on = [
    databricks_metastore_assignment.this
  ]
}

resource "databricks_grants" "some" {
  external_location = databricks_external_location.some.id
  grant {
    principal  = "Data Engineers"
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES"]
  }
}


resource "databricks_volume" "my_blob_volume" {
  name              = "blob_volume"
  catalog_name	  = databricks_catalog.scientific.name
  external_location = databricks_external_location.external_location.name
  volume_type = "EXTERNAL"
  storage_location = databricks_external_location.some.url
  comment           = "Volume for storing flat files in Azure Blob Storage"
}
