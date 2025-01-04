/* terraform {
  backend "azurerm" {
    key      = "terraform.tfstate"
    use_oidc = true
  }
} */

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
