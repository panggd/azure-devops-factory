# Azure DevOps Factory Repository

This repository facilitates the deployment of an Azure DevOps (ADO) factory, empowering application teams to self-service in provisioning repositories and pipelines.

## 🚀 Getting Started

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html)
- Azure DevOps organization and project
- Service principal with necessary permissions

### Setup Instructions

1. **Clone the Repository**

   ```bash
   git clone https://github.com/panggd/azure-devops-factory.git
   cd azure-devops-factory

2. **Run init sh**

   ```bash
   sh init.sh

3. **Terraform init and plan**

   ```bash
   cd terraform
   terraform init
   terraform plan

## 🛠 Features

- **Self-Service Provisioning**: Enables app teams to spin up their own repos and pipelines.
- **Modular IaC**: Promotes reusability with structured Terraform modules.
- **Automation Scripts**: Includes CLI helpers to bootstrap and maintain DevOps setup.
- **Terraform-Backed**: Uses `azuredevops_*` resources to declaratively manage ADO.
- **GitOps-Ready**: Repo structure is optimized for Git-based workflows.

## 📄 Documentation

For detailed usage and module configuration, refer to:

- Inline documentation in `terraform/modules/`
- [Azure DevOps Terraform Provider Docs](https://registry.terraform.io/providers/microsoft/azuredevops/latest)
- [Terraform CLI Reference](https://developer.hashicorp.com/terraform/cli)
- (Optional) Organization-specific guidance in the `docs/` directory
