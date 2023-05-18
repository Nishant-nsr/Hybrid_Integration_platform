terraform {

  required_providers {
    azurerm = {
      version = "3.55.0"
    }
  }
}

#---------------------------------------------------------------------

provider "azurerm" {
  features {}
}
