# OpenRemote Azure pipeline

This guide will help you set up everything to get started with the pipeline in GitHub Actions, Azure and Terraform.

## Naming conventions
The [Abbreviation recommendations for Azure resources](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations) have been used for naming resources in Terraform.

## Prerequisites

- Azure account
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) installed
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- GitHub account

## Step 1: Clone the Repository

```sh
git clone https://github.com/openremote/openremote-azure-pipeline.git
cd openremote-azure-pipeline
```

## Step 2: Configure Azure CLI

Log in to your Azure account using the Azure CLI:

```sh
az login
```

## Step 3: Set Up Terraform

Initialize Terraform:

```sh
terraform init
```

## Step 4: Configure OIDC Authentication

[Azure Provider: Authenticating using a Service Principal with Open ID Connect](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_oidc)

## Step 5: Store Secrets and variables in GitHub Repository

Go to your GitHub repository settings and add the following secrets:

- `ARM_CLIENT_ID`: The application `clientId` from the Azure Entra (previously called Azure AD) App created in the previous step.
- `ARM_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `ARM_TENANT_ID`: Your Azure tenant ID.
- `RESOURCE_GROUP_NAME`: Name of the Azure resource group that will be created
- `SSH_PUBLIC_KEY`: SSH key
- `SSH_SOURCE_IP`: IP address that's allowed to SSH into virtual machine
- `STORAGE_ACCOUNT`: Name of the Azure storage account that will be created (e.g. openremotestorage)
- `CONTAINER_NAME`: Name of the container that will be created (e.g. tfstate)

The `TF_ACTIONS_WORKING_DIR` variable can be set in the `Repository variables`. It should point to the folder where Terraform lives.

## Step 6: Add terraform.tfvars file
Add a terraform.tfvars file locally, in which at least the following variables should be added:

```go
subscription_id     = ""
ssh_source_ip       = "0.0.0.0/32"
alert_email_address = ""
```

The other variables that are in `variables.tf` can also be added if you want to override the default values, for example to deploy in a different region.

## Step 7: Add state_override.tf
Add a state_override.tf file locally and add the following content:


```go
terraform {
  backend "local" {
  }
}
```

This configures Terraform to use a local backend for state mangement. It makes sure the remote state isn't effected.

## Step 8: Apply Terraform Configuration

Run the following command to apply the Terraform configuration:

```sh
terraform apply
```

This will deploy OpenRemote in Azure using the local configuration.

## Step 9: Deployment via GitHub Actions

In the GitHub repository, go to the 'Actions' tab and select the 'Deploy OpenRemote' flow.
In the top right corner, hit the 'Run workflow' button. Here you can enter the desired values and start the workflow, which will deploy OpenRemote to Azure:

![Image of triggering the workflow in GitHub Actions](./docs/img/Github-Actions-Workflow.png)

## Conclusion

You have successfully set up the pipeline using GitHub Actions. You can now start building and deploying.

For more information, refer to the [Terraform Azure Provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs) and the [GitHub Actions documentation](https://docs.github.com/en/actions).

## Recommendations
