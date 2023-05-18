resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}
#-------------------- Network security group & Rules ------------------------

resource "azurerm_network_security_group" "example" {
  name                = var.nsg_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
resource "azurerm_network_security_rule" "example" {
  name                        = "test123"
  priority                    = 110
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.example.name
  network_security_group_name = azurerm_network_security_group.example.name
}

#---------------------- Route Table -------------------------------------------

resource "azurerm_route_table" "example" {
  name                          = var.route_table_name
  location                      = azurerm_resource_group.example.location
  resource_group_name           = azurerm_resource_group.example.name
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "10.0.0.0/8"
    next_hop_type  = "None"
  }
}

#------------------- Vnet --------------------------------------------

resource "azurerm_resource_group_template_deployment" "example" {
  name                = var.template_name
  resource_group_name = azurerm_resource_group.example.name
  template_content    = file("vnet_template.json")
  parameters_content  = jsonencode(
    {
      "vnetName" = {
        value = var.vnet_name
      },
      "subnetName" = {
        value = var.subnet1_name
      },
      "networkSecurityGroups_logicapp_nsg_externalid" = {
        value = azurerm_network_security_group.example.id
      },
      "routeTables_example_route_table_externalid" = {
        value = azurerm_route_table.example.id
      }
      "subnet2_name" = {
        value = var.subnet2_name
      }
  })
  deployment_mode = "Incremental"
}

#-------------- Data of Vnet & Subnets ------------------------------

data "azurerm_virtual_network" "example" {
  name                = var.vnet_name
  resource_group_name = azurerm_resource_group.example.name
  depends_on          = [azurerm_resource_group_template_deployment.example]
}
data "azurerm_subnet" "subnet1" {
  name                 = var.subnet1_name
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  depends_on           = [azurerm_resource_group_template_deployment.example]

}
data "azurerm_subnet" "subnet2" {
  name                 = var.subnet2_name
  virtual_network_name = data.azurerm_virtual_network.example.name
  resource_group_name  = azurerm_resource_group.example.name
  depends_on           = [azurerm_resource_group_template_deployment.example]
}


#--------------- Storage Account (containers,file shares and tables) ----------------------------------

resource "azurerm_storage_account" "example" {
  name                            = var.storage_accnt
  resource_group_name             = azurerm_resource_group.example.name
  location                        = azurerm_resource_group.example.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  enable_https_traffic_only       = true
  access_tier                     = "Hot"
  network_rules {
    default_action             = "Deny"
    ip_rules                   = ["13.234.188.94"]
    virtual_network_subnet_ids = [data.azurerm_subnet.subnet1.id, data.azurerm_subnet.subnet2.id]
  }
  identity {
    type = "SystemAssigned"
  }
  depends_on = [azurerm_resource_group_template_deployment.example]

}

resource "azurerm_storage_share" "example" {
  count                = length(var.sharename)
  name                 = var.sharename[count.index]
  storage_account_name = azurerm_storage_account.example.name
  quota                = 50
}
resource "azurerm_storage_container" "example" {
  count                 = length(var.container_name)
  name                  = var.container_name[count.index]
  storage_account_name  = azurerm_storage_account.example.name
  container_access_type = "private"

}
resource "azurerm_storage_table" "example" {
  name                 = var.table_name
  storage_account_name = azurerm_storage_account.example.name

}

#------------------------ Blob Private Endpoints------------------------------------

resource "azurerm_private_endpoint" "example" {
  name                = "logic-blob-privateendpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = data.azurerm_subnet.subnet2.id

  private_service_connection {
    name                           = "MyBlobPrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "example-blob-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example.id]
  }
}
#--------------------- Blob Private DNS Zone ----------------------------------

resource "azurerm_private_dns_zone" "example" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "example-blob-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example.name
  virtual_network_id    = data.azurerm_virtual_network.example.id
}

#-------------------------Queue Private Endpoint--------------------------------------------

resource "azurerm_private_endpoint" "example1" {
  name                = "logic-queue-privateendpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = data.azurerm_subnet.subnet2.id

  private_service_connection {
    name                           = "MyqueuePrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["queue"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "example-queue-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example1.id]
  }
}
#----------------------Queue DNS Zone ---------------------------------------

resource "azurerm_private_dns_zone" "example1" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example1" {
  name                  = "example-queue-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example1.name
  virtual_network_id    = data.azurerm_virtual_network.example.id
}

#----------------------File share Private Endpoint------------------------------------------------

resource "azurerm_private_endpoint" "example2" {
  name                = "logic-fileshare-privateendpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = data.azurerm_subnet.subnet2.id

  private_service_connection {
    name                           = "MyfilesharePrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "example-fileshare-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example2.id]
  }
}

#----------------------- File share Private DNS Zone----------------------------

resource "azurerm_private_dns_zone" "example2" {
  name                = "privatelink.fileshare.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example2" {
  name                  = "example-fileshare-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example2.name
  virtual_network_id    = data.azurerm_virtual_network.example.id
}

#--------------Table private Endpoint------------------------

resource "azurerm_private_endpoint" "example3" {
  name                = "logic-table-privateendpoint"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = data.azurerm_subnet.subnet2.id

  private_service_connection {
    name                           = "MytablePrivateLinkConnection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["table"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "example-table-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.example3.id]
  }
}
#-----------------Table private DNS Zone --------------------------

resource "azurerm_private_dns_zone" "example3" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example3" {
  name                  = "example-table-link"
  resource_group_name   = azurerm_resource_group.example.name
  private_dns_zone_name = azurerm_private_dns_zone.example3.name
  virtual_network_id    = data.azurerm_virtual_network.example.id
}

#------------------------------- Log Analytics Workspace -------------------------

resource "azurerm_log_analytics_workspace" "la_workspace" {
  name                = var.workspace_name
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "PerGB2018"
}

#---------------------Application Insights ---------------------------------

resource "azurerm_application_insights" "example" {
  name                = "logic-test-appinsights"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  workspace_id        = azurerm_log_analytics_workspace.la_workspace.id
  application_type    = "web"
}

#------------------- Standard Logic Apps -----------------------------------

resource "azurerm_resource_group_template_deployment" "example01" {
  name                = "logicapp-deploy"
  resource_group_name = azurerm_resource_group.example.name
  template_content    = file("logic app.json")
  parameters_content  = jsonencode(
    {
      "logicAppFEname" = {
        value = var.logic_app_names[0]
      },
      "logicApp1name" = {
        value = var.logic_app_names[1]
      },
      "logicApp2name" = {
        value = var.logic_app_names[2]
      },
      "runtimeurlsalesforce" = {
        value = jsondecode(data.local_file.connection_Output.content)
      },
      "runtimeurleventgridtable" = {
        value = jsondecode(data.local_file.connection_Output3.content)
      },
      "runtimeurleventgrid" = {
        value = jsondecode(data.local_file.connection_Output2.content)
      },
      "networkSecurityGroups_logicapp_nsg_externalid" = {
        value = azurerm_network_security_group.example.id
      },
      "routeTables_logicapp_route_table_externalid" = {
        value = azurerm_route_table.example.id
      },
      "fileShareName" = {
        value = var.sharename[0]
      },
      "fileShareName1" = {
        value = var.sharename[1]
      },
      "fileShareName2" = {
        value = var.sharename[2]
      },
      "container_name1" = {
        value = var.container_name[0]
      },
      "container_name2" = {
        value = var.container_name[1]
      },
      "contentStorageAccountName" = {
        value = var.storage_accnt
      },
      "vnetName" = {
        value = var.vnet_name
      },
      "subnetName" = {
        value = var.subnet1_name
      }
    }
  )

  deployment_mode = "Incremental"

  depends_on = [azurerm_storage_account.example, azurerm_resource_group_template_deployment.example1]
}

# resource "azurerm_eventgrid_event_subscription" "example" {
#   name  = var.eventgrid_sub_name
#   scope = azurerm_azurerm_eventgrid_topic.example.id
#   event_delivery_schema = "EventGridSchema"
#   included_event_types = "Microsoft.Storage.BlobCreated"

#  webhook_endpoint {
#     url = data.azurerm_logic_app_workflow.example.access_endpoint
#     max_events_per_batch = 1
#     preferred_batch_size_in_kilobytes = 64
#  }
#  retry_policy {
#     max_delivery_attempts = 30
#     event_time_to_live = 1440
#  }
# }

# resource "azurerm_eventgrid_system_topic" "example" {
#   name                   = var.eventgrid_system_topic_name
#   resource_group_name    = azurerm_resource_group.example.name
#   location               = azurerm_resource_group.example.location
#   source_arm_resource_id = azurerm_storage_account.example.id
#   topic_type             = "Microsoft.Storage.StorageAccounts"
# }

# resource "azurerm_eventgrid_system_topic_event_subscription" "example" {
#   name                = var.eventgrid_sys_sub_name
#   system_topic        = azurerm_eventgrid_system_topic.example.name
#   resource_group_name = azurerm_resource_group.example.name
#   event_delivery_schema = "EventGridSchema"
#   included_event_types = "Microsoft.Storage.BlobCreated"

#  webhook_endpoint {
#     url = data.azurerm_logic_app_workflow.example.access_endpoint
#     max_events_per_batch = 1
#     preferred_batch_size_in_kilobytes = 64
#  }
#  retry_policy {
#     max_delivery_attempts = 30
#     event_time_to_live = 1440
#  }
# }

resource "azurerm_eventgrid_topic" "example" {
  name                = "eventgridlogicapp"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}
data "azurerm_eventgrid_topic" "example" {
  name                = azurerm_eventgrid_topic.example.name
  resource_group_name = azurerm_resource_group.example.name
  depends_on          = [azurerm_eventgrid_topic.example]
}
#--------------------- API Connections-------------------------------------

resource "azurerm_resource_group_template_deployment" "example1" {
  name                = "template2"
  resource_group_name = azurerm_resource_group.example.name
  template_content    = file("apiconnectionSalesforce.json")
  parameters_content  = jsonencode(
    {
      "connections_salesforce_name" = {
        value = "salesforce"
      },
      "subscription_id" = {
        value = "7c5fbe39-ada3-4728-8e6f-506a6df63e70"
      },
      "resource_grp_name" = {
        value = azurerm_resource_group.example.name
      },
      "connections_azureeventgrid_name" = {
        value = "azureeventgrid"
      },
      "eventgrid_endpoint" = {
        value = data.azurerm_eventgrid_topic.example.endpoint
      },
      "eventgrid_key" = {
        value = data.azurerm_eventgrid_topic.example.primary_access_key
      },
      "connections_azureeventgridpublish_name" = {
        value = "azureeventgridpublish"
      }



    }
  )
  deployment_mode = "Incremental"
}
#-----------------------Access Policies ------------------------------------

resource "azurerm_resource_group_template_deployment" "access_poilcy" {
  name                = "access_policy_template"
  resource_group_name = azurerm_resource_group.example.name
  template_content    = file("access_policy.json")
  parameters_content  = jsonencode(
    {
      "logicAppSystemAssignedIdentityTenantId" = {
        value = data.azurerm_logic_app_standard.example[0].identity[0].tenant_id
      }
      "logicAppSystemAssignedIdentityObjectId" = {
        value = data.azurerm_logic_app_standard.example[0].identity[0].principal_id
      }
      "logicApp1SystemAssignedIdentityTenantId" = {
        value = data.azurerm_logic_app_standard.example[1].identity[0].tenant_id
      }
      "logicApp1SystemAssignedIdentityObjectId" = {
        value = data.azurerm_logic_app_standard.example[1].identity[0].principal_id
      }
      "logicApp2SystemAssignedIdentityTenantId" = {
        value = data.azurerm_logic_app_standard.example[2].identity[0].tenant_id
      }
      "logicApp2SystemAssignedIdentityObjectId" = {
        value = data.azurerm_logic_app_standard.example[2].identity[0].principal_id
      }
    }
  )
  deployment_mode = "Incremental"
}

#------------------------- API Runtime URl Connections Informations ---------------------------------------

resource "null_resource" "exec_az_command1" {
  provisioner "local-exec" {
    command = "az resource show --ids /subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.example.name}/providers/Microsoft.Web/connections/${var.connections_salesforce_name} --query properties.connectionRuntimeUrl --output json > file1.json"
  }
  depends_on = [azurerm_resource_group_template_deployment.example1]
}

data "local_file" "connection_Output" {
  filename   = "file.json"
  depends_on = [null_resource.exec_az_command1]

}
resource "null_resource" "exec_az_command3" {
  provisioner "local-exec" {
    command = "az resource show --ids /subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.example.name}/providers/Microsoft.Web/connections/${var.connections_azureeventgridpublish_name} --query properties.connectionRuntimeUrl --output json > file3.json"
  }
  depends_on = [azurerm_resource_group_template_deployment.example1]
}
data "local_file" "connection_Output3" {
  filename   = "file3.json"
  depends_on = [null_resource.exec_az_command3]

}
resource "null_resource" "exec_az_command2" {
  provisioner "local-exec" {
    command = "az resource show --ids /subscriptions/${var.subscription_id}/resourceGroups/${azurerm_resource_group.example.name}/providers/Microsoft.Web/connections/${var.connections_azureeventgrid_name} --query properties.connectionRuntimeUrl --output json > file2.json"
  }
  depends_on = [azurerm_resource_group_template_deployment.example1]
}
data "local_file" "connection_Output2" {
  filename   = "file2.json"
  depends_on = [null_resource.exec_az_command1]

}

#--------------------------- Logic Apps Data Informations ---------------------

data "azurerm_logic_app_standard" "example" {
  count               = length(var.logic_app_names)
  name                = var.logic_app_names[count.index]
  resource_group_name = azurerm_resource_group.example.name
  depends_on          = [azurerm_resource_group_template_deployment.example01]

}

#----------------------- Role Assingments ---------------------------------

resource "azurerm_role_assignment" "example0" {
  count                = length(var.logic_app_names)
  scope                = azurerm_storage_account.example.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_logic_app_standard.example[count.index].identity[0].principal_id
  depends_on           = [azurerm_resource_group_template_deployment.example01]

}


#------------------------- event grid Topic & Subscription ----------------------------------------

resource "azurerm_eventgrid_system_topic" "example" {
  name                   = var.eventgrid_system_topic_name
  resource_group_name    = azurerm_resource_group.example.name
  location               = azurerm_resource_group.example.location
  source_arm_resource_id = azurerm_storage_account.example.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}


data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "example" {
  name                            = "logicappkeyvault56798"
  location                        = azurerm_resource_group.example.location
  resource_group_name             = azurerm_resource_group.example.name
  enabled_for_disk_encryption     = false
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 14
  purge_protection_enabled        = true
  enabled_for_deployment          = false
  enabled_for_template_deployment = false
  enable_rbac_authorization       = true
  public_network_access_enabled   = false


  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "List",
      "Create",
      "Purge",
      "Recover",
      "Restore"
    ]

    secret_permissions = [
      "Get",
      "Backup",
      "List",
      "Recover",
      "Set",
      "Restore"
    ]

    storage_permissions = [
      "Get",
    ]
  }

}


# resource "azurerm_private_endpoint" "logicapp2" {
#   count               = length(var.logic_app_names)
#   name                = var.private_endpoint_names[count.index]
#   location            = azurerm_resource_group.example.location
#   resource_group_name = azurerm_resource_group.example.name

#   subnet_id = data.azurerm_subnet.subnet2.id
#   private_service_connection {
#     name                           = var.private_svc_connt_names[count.index]
#     private_connection_resource_id = data.azurerm_logic_app_standard.example[count.index].id
#     is_manual_connection           = false
#     subresource_names              = ["sites"]
#   }
#   depends_on = [data.azurerm_logic_app_standard.example[2]]
# }