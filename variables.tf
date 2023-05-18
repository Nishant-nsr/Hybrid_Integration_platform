# Define variables
variable "location" {
  type    = string
  default = "East US"
}

variable "resource_group_name" {
  type    = string
  default = "Hybrid-rg"
}

variable "nsg_name" {
  type    = string
  default = "logicapp-nsg"
}
variable "connections_salesforce_name" {
  type    = string
  default = "salesforce"
}
variable "connections_azureeventgrid_name" {
  type    = string
  default = "azureeventgrid"
}
variable "connections_azureeventgridpublish_name" {
  type    = string
  default = "azureeventgridpublish"
}

variable "private_endpoint_names" {
  type    = list(string)
  default = ["logicapp-private-endpoint0", "logicapp-private-endpoint1", "logicapp-private-endpoint2", "logicapp-private-endpoint3"]
}

variable "private_link_service_name" {
  type    = string
  default = "logicapp-private-link-service"
}
variable "vnet_name" {
  type    = string
  default = "LAV2VNET"
}
variable "ip_address" {
  type    = list(string)
  default = ["35.154.246.152", "155.201.150.21"]
}
variable "subnet1_name" {
  type    = string
  default = "Subnet1"
}

variable "subnet2_name" {
  type    = string
  default = "lav2withsecuredstorage"
}
variable "subnet3_name" {
  type    = string
  default = "default"
}

variable "lb_name" {
  type    = string
  default = "logicapp-lb"
}

variable "public_ip1_name" {
  type    = string
  default = "logicapp-public-ip1"
}

variable "public_ip2_name" {
  type    = string
  default = "logicapp-public-ip2"
}
variable "route_table_name" {
  type    = string
  default = "logicapp-route-table"
}
variable "template_name" {
  type    = string
  default = "vnet-deployment"
}
variable "logic_app_names" {
  type    = list(string)
  default = ["Logicworkflow11", "Logicsecondworkflow22", "Logicthirdworkflow33"]
}
variable "private_svc_connt_names" {
  type    = list(string)
  default = ["Logicsvcconnect0", "Logicsvcconnect1", "Logicsvcconnect2", "Logicsvcconnect3"]
}
variable "subnets_id" {
  type    = list(string)
  default = ["/subscriptions/7c5fbe39-ada3-4728-8e6f-506a6df63e70/resourceGroups/HybridEnv-rg/providers/Microsoft.Network/virtualNetworks/virtnetname/subnets/mainsubnet", "/subscriptions/7c5fbe39-ada3-4728-8e6f-506a6df63e70/resourceGroups/HybridEnv-rg/providers/Microsoft.Network/virtualNetworks/virtnetname/subnets/Logicapp1outboundSubnet", "/subscriptions/7c5fbe39-ada3-4728-8e6f-506a6df63e70/resourceGroups/HybridEnv-rg/providers/Microsoft.Network/virtualNetworks/virtnetname/subnets/Logicapp2outboundSubnet", "/subscriptions/7c5fbe39-ada3-4728-8e6f-506a6df63e70/resourceGroups/HybridEnv-rg/providers/Microsoft.Network/virtualNetworks/virtnetname/subnets/Logicapp3outboundSubnet"]
}
variable "container_name" {
  type    = list(string)
  default = ["logic-container1", "logic-container2"]
}
variable "workspace_name" {
  type    = string
  default = "logic-workspace459"
}
variable "insight_name" {
  type    = string
  default = "logic-app-insight047"
}
variable "eventgrid_topic_name" {
  type    = string
  default = "logicappevnttopi76"
}
variable "eventgridsubscription" {
  type    = string
  default = "eventgridsub1"
}
variable "sharename" {
  type    = list(string)
  default = ["logicshare1", "logicshare2", "logicshare3"]
}
variable "storage_accnt" {
  type    = string
  default = "logicappstoraccnt89446"
}
variable "app_svc_name" {
  type    = string
  default = "logicappsvcplan456"
}
variable "table_name" {
  type    = string
  default = "logicapptable29865"
}
variable "queue_name" {
  type    = string
  default = "logicappqueue29865"
}
variable "eventgrid_system_topic_name" {
  type    = string
  default = "logicappevntsystopi76"
}
variable "eventgrid_sys_sub_name" {
  type    = string
  default = "logicappevntsyssub5"
}
variable "subscription_id" {
  type    = string
  default = "7c5fbe39-ada3-4728-8e6f-506a6df63e70"
}