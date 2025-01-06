terraform {
  backend "azurerm" {
    key      = "terraform.tfstate"
    use_oidc = true
  }
}