provider "azurerm" {
  features {
  }
subscription_id = var.F-SubscriptionID
}

#variables
variable "A-location" {
    description = "Location of the resources, example: eastus2"
    #default     = "eastus"
}

variable "B-resource_group_name" {
    description = "Name of the resource group to create"
}

variable "C-home_public_ip" {
    description = "Your home public ip address"
}

variable "D-username" {
    description = "Username for Virtual Machines"
    #default     = "azureuser"
}

variable "E-password" {
    description = "Password for Virtual Machines"
    sensitive = true
}

variable "F-SubscriptionID" {
  description = "Subscription ID to use"  
}


resource "azurerm_resource_group" "RG" {
  location = var.A-location
  name     = var.B-resource_group_name
}

#logic app to self destruct resourcegroup after 24hrs
data "azurerm_subscription" "sub" {
}

resource "azurerm_logic_app_workflow" "workflow1" {
  location = azurerm_resource_group.RG.location
  name     = "labdelete"
  resource_group_name = azurerm_resource_group.RG.name
  identity {
    type = "SystemAssigned"
  }
  depends_on = [
    azurerm_resource_group.RG,
  ]
}
resource "azurerm_role_assignment" "contrib1" {
  scope = azurerm_resource_group.RG.id
  role_definition_name = "Contributor"
  principal_id  = azurerm_logic_app_workflow.workflow1.identity[0].principal_id
  depends_on = [azurerm_logic_app_workflow.workflow1]
}

resource "azurerm_resource_group_template_deployment" "apiconnections" {
  name                = "group-deploy"
  resource_group_name = azurerm_resource_group.RG.name
  deployment_mode     = "Incremental"
  template_content = <<TEMPLATE
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "variables": {},
    "resources": [
        {
            "type": "Microsoft.Web/connections",
            "apiVersion": "2016-06-01",
            "name": "arm-1",
            "location": "${azurerm_resource_group.RG.location}",
            "kind": "V1",
            "properties": {
                "displayName": "labdeleteconn1",
                "authenticatedUser": {},
                "statuses": [
                    {
                        "status": "Ready"
                    }
                ],
                "connectionState": "Enabled",
                "customParameterValues": {},
                "alternativeParameterValues": {},
                "parameterValueType": "Alternative",
                "createdTime": "2023-05-21T23:07:20.1346918Z",
                "changedTime": "2023-05-21T23:07:20.1346918Z",
                "api": {
                    "name": "arm",
                    "displayName": "Azure Resource Manager",
                    "description": "Azure Resource Manager exposes the APIs to manage all of your Azure resources.",
                    "iconUri": "https://connectoricons-prod.azureedge.net/laborbol/fixes/path-traversal/1.0.1552.2695/arm/icon.png",
                    "brandColor": "#003056",
                    "id": "/subscriptions/${data.azurerm_subscription.sub.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.RG.location}/managedApis/arm",
                    "type": "Microsoft.Web/locations/managedApis"
                },
                "testLinks": []
            }
        },
        {
            "type": "Microsoft.Logic/workflows",
            "apiVersion": "2017-07-01",
            "name": "labdelete",
            "location": "${azurerm_resource_group.RG.location}",
            "dependsOn": [
                "[resourceId('Microsoft.Web/connections', 'arm-1')]"
            ],
            "identity": {
                "type": "SystemAssigned"
            },
            "properties": {
                "state": "Enabled",
                "definition": {
                    "$schema": "https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#",
                    "contentVersion": "1.0.0.0",
                    "parameters": {
                        "$connections": {
                            "defaultValue": {},
                            "type": "Object"
                        }
                    },
                    "triggers": {
                        "Recurrence": {
                            "recurrence": {
                                "frequency": "Minute",
                                "interval": 3,
                                "startTime": "${timeadd(timestamp(),"24h")}"
                            },
                            "evaluatedRecurrence": {
                                "frequency": "Minute",
                                "interval": 3,
                                "startTime": "${timeadd(timestamp(),"24h")}"
                            },
                            "type": "Recurrence"
                        }
                    },
                    "actions": {
                        "Delete_a_resource_group": {
                            "runAfter": {},
                            "type": "ApiConnection",
                            "inputs": {
                                "host": {
                                    "connection": {
                                        "name": "@parameters('$connections')['arm']['connectionId']"
                                    }
                                },
                                "method": "delete",
                                "path": "/subscriptions/@{encodeURIComponent('${data.azurerm_subscription.sub.subscription_id}')}/resourcegroups/@{encodeURIComponent('${azurerm_resource_group.RG.name}')}",
                                "queries": {
                                    "x-ms-api-version": "2016-06-01"
                                }
                            }
                        }
                    },
                    "outputs": {}
                },
                "parameters": {
                    "$connections": {
                        "value": {
                            "arm": {
                                "connectionId": "[resourceId('Microsoft.Web/connections', 'arm-1')]",
                                "connectionName": "arm-1",
                                "connectionProperties": {
                                    "authentication": {
                                        "type": "ManagedServiceIdentity"
                                    }
                                },
                                "id": "/subscriptions/${data.azurerm_subscription.sub.subscription_id}/providers/Microsoft.Web/locations/${azurerm_resource_group.RG.location}/managedApis/arm"
                            }
                        }
                    }
                }
            }
        }
    ]
}
TEMPLATE
}


#vwan and hub
resource "azurerm_virtual_wan" "vwan1" {
  name                = "vwan1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
    timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_wan" "vwan2" {
  name                = "vwan2"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
    timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

resource "azurerm_virtual_hub" "vhub1" {
  name                = "vhub1"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_prefix      = "10.0.0.0/16"
    timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_hub" "vhub2" {
  name                = "vhub2"
  resource_group_name = azurerm_resource_group.RG.name
  location            = azurerm_resource_group.RG.location
  virtual_wan_id      = azurerm_virtual_wan.vwan2.id
  address_prefix      = "10.10.0.0/16"
    timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_vpn_gateway" "hub1vpngw" {
  resource_group_name = azurerm_resource_group.RG.name
  name                = "hub1vpngw"
  location            = azurerm_resource_group.RG.location
  virtual_hub_id      = azurerm_virtual_hub.vhub1.id
}
resource "azurerm_vpn_gateway" "hub2vpngw" {
  resource_group_name = azurerm_resource_group.RG.name
  name                = "hub2vpngw"
  location            = azurerm_resource_group.RG.location
  virtual_hub_id      = azurerm_virtual_hub.vhub2.id
}

data "azurerm_vpn_gateway" "hub1pip" {
  name                = azurerm_vpn_gateway.hub1vpngw.name
  resource_group_name = azurerm_resource_group.RG.name
  
}
data "azurerm_vpn_gateway" "hub2pip" {
  name                = azurerm_vpn_gateway.hub2vpngw.name
  resource_group_name = azurerm_resource_group.RG.name
  
}

resource "azurerm_vpn_site" "hub2vpn" {
  device_vendor       = "Azure"
  location            = azurerm_resource_group.RG.location
  name                = "vpntohub2"
  resource_group_name = azurerm_resource_group.RG.name
  virtual_wan_id      = azurerm_virtual_wan.vwan1.id
  address_cidrs = ["10.10.0.0/16","10.250.0.0/16"]
  link {
    ip_address    = data.azurerm_vpn_gateway.hub2pip.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips[0]
    name          = "vpnlink"
    provider_name = "Azure"
    speed_in_mbps = 10
    
  }
}
resource "azurerm_vpn_site" "hub1vpn" {
  device_vendor       = "Azure"
  location            = azurerm_resource_group.RG.location
  name                = "vpntohub1"
  resource_group_name = azurerm_resource_group.RG.name
  virtual_wan_id      = azurerm_virtual_wan.vwan2.id
  address_cidrs = ["10.0.0.0/16","10.150.0.0/16"]
  link {
    ip_address    = data.azurerm_vpn_gateway.hub1pip.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips[0]
    name          = "vpnlink"
    provider_name = "Azure"
    speed_in_mbps = 10
    
  }
}

resource "azurerm_vpn_gateway_connection" "hub1connection" {
  internet_security_enabled = true
  name                      = "Connection-tohub2"
  remote_vpn_site_id        = azurerm_vpn_site.hub2vpn.id
  vpn_gateway_id            = azurerm_vpn_gateway.hub1vpngw.id
  vpn_link {
    bgp_enabled      = false
    name             = "linktohub2"
    shared_key       = "vpn123"
    vpn_site_link_id = azurerm_vpn_site.hub2vpn.link[0].id
  }
  
}
resource "azurerm_vpn_gateway_connection" "hub2connection" {
  internet_security_enabled = true
  name                      = "Connection-tohub1"
  remote_vpn_site_id        = azurerm_vpn_site.hub1vpn.id
  vpn_gateway_id            = azurerm_vpn_gateway.hub2vpngw.id
  vpn_link {
    bgp_enabled      = false
    name             = "linktohub1"
    shared_key       = "vpn123"
    vpn_site_link_id = azurerm_vpn_site.hub1vpn.link[0].id
  }
  
}

#spoke vnets
resource "azurerm_virtual_network" "spoke1-vnet" {
  address_space       = ["10.150.0.0/16"]
  location            = azurerm_resource_group.RG.location
  name                = "spoke1-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  subnet {
    address_prefixes     = ["10.150.0.0/24"]
    name                 = "default"
    security_group = azurerm_network_security_group.spokevnetNSG.id
  }
  subnet {
    address_prefixes    = ["10.150.1.0/24"]
    name                 = "GatewaySubnet" 
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_network" "spoke2-vnet" {
  address_space       = ["10.250.0.0/16"]
  location            = azurerm_resource_group.RG.location
  name                = "spoke2-vnet"
  resource_group_name = azurerm_resource_group.RG.name
  subnet {
    address_prefixes     = ["10.250.0.0/24"]
    name                 = "default"
    security_group = azurerm_network_security_group.spokevnetNSG.id
  }
  subnet {
    address_prefixes     = ["10.250.1.0/24"]
    name                 = "GatewaySubnet" 
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}



#vnet connections to hub
resource "azurerm_virtual_hub_connection" "tospoke1" {
  name                      = "tospoke1"
  internet_security_enabled = true
  virtual_hub_id            = azurerm_virtual_hub.vhub1.id
  remote_virtual_network_id = azurerm_virtual_network.spoke1-vnet.id
}
resource "azurerm_virtual_hub_connection" "tospoke2" {
  name                      = "tospoke2"
  internet_security_enabled = true
  virtual_hub_id            = azurerm_virtual_hub.vhub2.id
  remote_virtual_network_id = azurerm_virtual_network.spoke2-vnet.id
}

#NSG
resource "azurerm_network_security_group" "spokevnetNSG" {
  location            = azurerm_resource_group.RG.location
  name                = "spoke-vnet-default-nsg"
  resource_group_name = azurerm_resource_group.RG.name
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_security_rule" "spokevnetnsgrule1" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "3389"
  direction                   = "Inbound"
  name                        = "AllowCidrBlockRDPInbound"
  network_security_group_name = "spoke-vnet-default-nsg"
  priority                    = 2711
  protocol                    = "Tcp"
  resource_group_name         = azurerm_network_security_group.spokevnetNSG.resource_group_name
  source_address_prefix       = var.C-home_public_ip
  source_port_range           = "*"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}


#Public ip's
resource "azurerm_public_ip" "spoke1vm-pip" {
  name                = "spoke1vm-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Static"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_public_ip" "spoke2vm-pip" {
  name                = "spoke2vm-pip"
  location            = azurerm_resource_group.RG.location
  resource_group_name = azurerm_resource_group.RG.name
  allocation_method = "Static"
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#vnic's
resource "azurerm_network_interface" "spoke1vm-nic" {
  location            = azurerm_resource_group.RG.location
  name                = "spoke1vm-nic"
  resource_group_name = azurerm_resource_group.RG.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke1vm-pip.id
    subnet_id                     = azurerm_virtual_network.spoke1-vnet.subnet.*.id[0]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_network_interface" "spoke2vm-nic" {
  location            = azurerm_resource_group.RG.location
  name                = "spoke2vm-nic"
  resource_group_name = azurerm_resource_group.RG.name
  ip_configuration {
    name                          = "ipconfig1"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.spoke2vm-pip.id
    subnet_id                     = azurerm_virtual_network.spoke2-vnet.subnet.*.id[0]
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}

#VM's
resource "azurerm_windows_virtual_machine" "spoke1vm" {
  admin_password        = var.E-password
  admin_username        = var.D-username
  location              = azurerm_resource_group.RG.location
  name                  = "spoke1vm"
  network_interface_ids = [azurerm_network_interface.spoke1vm-nic.id]
  resource_group_name   = azurerm_resource_group.RG.name
  size                  = "Standard_B2ms"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_machine_extension" "killspoke1vmfirewall" {
  auto_upgrade_minor_version = true
  name                       = "killspoke1vmfirewall"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.spoke1vm.id
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -command \"Set-NetFirewallProfile -Enabled False\""
    }
  SETTINGS
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_windows_virtual_machine" "spoke2vm" {
  admin_password        = var.E-password
  admin_username        = var.D-username
  location              = azurerm_resource_group.RG.location
  name                  = "spoke2vm"
  network_interface_ids = [azurerm_network_interface.spoke2vm-nic.id]
  resource_group_name   = azurerm_resource_group.RG.name
  size                  = "Standard_B2ms"
  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
resource "azurerm_virtual_machine_extension" "killspoke2vmfirewall" {
  auto_upgrade_minor_version = true
  name                       = "killspokevmfirewall"
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  virtual_machine_id         = azurerm_windows_virtual_machine.spoke2vm.id
  settings = <<SETTINGS
    {
      "commandToExecute": "powershell -command \"Set-NetFirewallProfile -Enabled False\""
    }
  SETTINGS
  timeouts {
    create = "2h"
    read = "2h"
    update = "2h"
    delete = "2h"
  }
  
}
