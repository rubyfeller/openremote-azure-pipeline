terraform {
  backend "azurerm" {
    key      = "${var.customer_name}/terraform.tfstate"
    use_oidc = true
  }
}