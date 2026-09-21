# 10Alytics DevOps Assessment

# Deployment Documentation

## 1. Overview

This document explains how to reproduce, provision and deploy the 10Alytics application.

The solution uses:

* Python Flask
* Docker
* GitHub
* GitHub Actions
* Terraform
* Microsoft Azure
* Azure Container Registry
* Azure Linux Virtual Machine
* Azure Application Gateway
* Azure Key Vault
* Azure Managed Identity
* Microsoft Entra ID
* Azure RBAC

The deployment process follows this sequence:

```text
Developer
    |
    v
GitHub
    |
    v
GitHub Actions
    |
    +--> Run Tests
    |
    +--> Terraform Validate
    |
    +--> Terraform Plan
    |
    +--> Approval
    |
    +--> Terraform Apply
    |
    +--> Build Docker Image
    |
    +--> Push Image to ACR
    |
    +--> Deploy to Azure VM
    |
    +--> Health Check
    |
    v
Application Gateway
    |
    v
Users
```

---

# 2. Prerequisites

Before reproducing the environment, install the following tools.

## Required Tools

### Git

Verify:

```powershell
git --version
```

### Python

Python 3.11 is used by the CI pipeline.

Verify:

```powershell
python --version
```

### Docker

Verify:

```powershell
docker --version
```

### Terraform

Verify:

```powershell
terraform version
```

### Azure CLI

Verify:

```powershell
az --version
```

### GitHub Account

A GitHub repository is required for the source code and GitHub Actions pipeline.

---

# 3. Repository Structure

The repository uses the following structure:

```text
10alytics/
├── README.md
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── OPERATIONS.md
│   └── SECURITY.md
│
├── app/
│   ├── application.py
│   ├── requirements.txt
│   ├── templates/
│   │   └── index.html
│   ├── static/
│   │   ├── css/
│   │   │   └── style.css
│   │   └── js/
│   │       └── app.js
│   └── tests/
│       └── test_app.py
│
├── terraform/
│   ├── backend.tf
│   ├── provider.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── main.tf
│   ├── identity.tf
│   ├── network.tf
│   ├── vm.tf
│   ├── acr.tf
│   └── keyvault.tf
│
├── .github/
│   └── workflows/
│       ├── ci-cd.yml
│       └── destroy.yml
│
├── Dockerfile
├── .dockerignore
└── .gitignore
```

---

# 4. Clone the Repository

Clone the repository:

```powershell
git clone https://github.com/Ianyalewechi/demo.git
```

Move into the project directory:

```powershell
cd demo
```

Verify the branch:

```powershell
git branch
```

The deployment branch is:

```text
main
```

---

# 5. Run the Application Locally

Move into the application directory:

```powershell
cd app
```

Create a Python virtual environment:

```powershell
python -m venv venv
```

Activate the environment:

```powershell
.\venv\Scripts\Activate.ps1
```

Upgrade pip:

```powershell
python -m pip install --upgrade pip
```

Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

---

# 6. Run Automated Tests Locally

From the `app` directory:

```powershell
python -m pytest -v
```

The expected result is:

```text
3 passed
```

The tests cover:

* Home page
* Health endpoint
* Readiness endpoint

---

# 7. Run the Flask Application

From the `app` directory:

```powershell
python application.py
```

The application should start on:

```text
http://127.0.0.1:5000/
```

Open the address in a browser.

---

# 8. Test Application Endpoints

## Home Page

```text
http://127.0.0.1:5000/
```

## Health

```text
http://127.0.0.1:5000/health
```

Expected response:

```json
{
  "status": "healthy"
}
```

## Readiness

```text
http://127.0.0.1:5000/health/ready
```

Expected response:

```json
{
  "status": "ready"
}
```

## Application Information

```text
http://127.0.0.1:5000/api/info
```

The endpoint returns application information including the application name, environment, status and version.

---

# 9. Build the Docker Image

Return to the project root:

```powershell
cd ..
```

Build the Docker image:

```powershell
docker build -t 10alytics-app:frontend .
```

Verify the image:

```powershell
docker images
```

The image should appear as:

```text
10alytics-app
```

---

# 10. Run the Docker Container Locally

Run:

```powershell
docker run -d `
  --name 10alytics-app `
  -p 5000:5000 `
  10alytics-app:frontend
```

Verify the container:

```powershell
docker ps
```

Open:

```text
http://localhost:5000/
```

Test health:

```text
http://localhost:5000/health
```

Test readiness:

```text
http://localhost:5000/health/ready
```

---

# 11. Stop the Local Container

To stop the container:

```powershell
docker stop 10alytics-app
```

Remove the container:

```powershell
docker rm 10alytics-app
```

---

# 12. Azure Authentication

The deployment environment uses Microsoft Entra ID and Azure Managed Identity.

GitHub Actions does not use a stored Azure client secret.

Instead, GitHub Actions authenticates using OpenID Connect.

The required GitHub repository secrets are:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
VM_SSH_PUBLIC_KEY
```

The following GitHub repository variables are also configured:

```text
AZURE_RESOURCE_GROUP
AZURE_LOCATION
ACR_NAME
VM_NAME
KEY_VAULT_NAME
```

---

# 13. GitHub Actions Environments

Two GitHub Environments are used.

## Terraform Apply

```text
terraform-apply
```

This environment protects infrastructure provisioning.

The Terraform Apply stage waits for the configured approval before applying infrastructure changes.

## Terraform Destroy

```text
terraform-destroy
```

This environment protects infrastructure destruction.

The destroy workflow is manually triggered and requires approval before the infrastructure is removed.

---

# 14. Terraform Configuration

Terraform configuration is located in:

```text
terraform/
```

Before using Terraform, authenticate with Azure:

```powershell
az login
```

Select the correct subscription:

```powershell
az account set --subscription "GO-SM-Digital-Factory-test"
```

Verify:

```powershell
az account show
```

---

# 15. Terraform Variables

Terraform requires environment specific values.

The local file is:

```text
terraform/terraform.tfvars
```

Example:

```hcl
resource_group_name = "rg-10alytics-devops"
location            = "West Europe"
vm_name             = "vm-10alytics"
acr_name            = "acr10alyticsikedi"
key_vault_name      = "kv10demo"
admin_username      = "azureuser"
ssh_public_key      = "YOUR_SSH_PUBLIC_KEY"
```

The `terraform.tfvars` file must not be committed to Git.

It is excluded through `.gitignore`.

---

# 16. Terraform Initialisation

Move into the Terraform directory:

```powershell
cd terraform
```

Initialise Terraform:

```powershell
terraform init
```

Terraform connects to the Azure remote state backend:

```text
Storage Account:
st10alyticstfstate

Container:
tfstate

State:
10alytics.tfstate
```

---

# 17. Terraform Format Validation

Run:

```powershell
terraform fmt -check
```

This checks Terraform formatting.

To automatically format the files:

```powershell
terraform fmt
```

---

# 18. Terraform Validation

Run:

```powershell
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

# 19. Terraform Plan

Generate an infrastructure plan:

```powershell
terraform plan
```

The plan should be reviewed before infrastructure changes are applied.

Terraform identifies:

* Resources to create
* Resources to modify
* Resources to destroy
* Configuration changes

---

# 20. Terraform Apply

For a manual deployment, apply the configuration:

```powershell
terraform apply
```

Review the proposed changes and confirm:

```text
yes
```

In the CI/CD pipeline, Terraform Apply is performed automatically only after the GitHub Environment approval has been granted.

---

# 21. Azure Infrastructure Provisioned by Terraform

Terraform provisions the core infrastructure required by the application.

```text
rg-10alytics-devops
        |
        +-- vnet-10alytics
        |
        +-- snet-10alytics
        |
        +-- snet-appgateway
        |
        +-- vm-10alytics
        |
        +-- id-10alytics-vm
        |
        +-- acr10alyticsikedi
        |
        +-- kv10demo
        |
        +-- agw-10alytics
        |
        +-- Azure Storage
```

---

# 22. Azure Container Registry

The Docker image is stored in:

```text
acr10alyticsikedi.azurecr.io
```

The CI/CD pipeline creates two tags:

```text
10alytics-app:<git-commit-sha>
10alytics-app:latest
```

For example:

```text
acr10alyticsikedi.azurecr.io/10alytics-app:8f3c1c9
```

The commit SHA provides application version traceability.

---

# 23. CI/CD Pipeline

The main workflow is:

```text
.github/workflows/ci-cd.yml
```

The pipeline is triggered when code is pushed to:

```text
main
```

It can also be started manually using GitHub Actions.

---

# 24. Pipeline Stage 1: Automated Testing

The first stage checks the application.

GitHub Actions:

1. Checks out the repository.
2. Installs Python 3.11.
3. Installs application dependencies.
4. Runs pytest.

Command:

```bash
python -m pytest -v
```

The pipeline must pass this stage before infrastructure deployment continues.

---

# 25. Pipeline Stage 2: Terraform Plan

After successful application tests, Terraform is initialised.

The pipeline performs:

```bash
terraform fmt -check
terraform validate
terraform plan
```

The Terraform plan is saved as an artifact:

```text
terraform-plan
```

The plan is reviewed before the infrastructure is changed.

---

# 26. Pipeline Stage 3: Terraform Approval

The Terraform Apply job uses:

```text
terraform-apply
```

GitHub Environment.

This introduces a manual approval point.

The flow is:

```text
Tests
   |
   v
Terraform Plan
   |
   v
Approval Required
   |
   v
Terraform Apply
```

This provides governance over infrastructure changes.

---

# 27. Pipeline Stage 4: Terraform Apply

After approval, the previously generated Terraform plan is downloaded.

Terraform applies the approved plan:

```bash
terraform apply -auto-approve tfplan
```

The infrastructure is therefore created or updated before application deployment begins.

---

# 28. Pipeline Stage 5: Docker Build

After Terraform Apply succeeds, GitHub Actions builds the Docker image.

Example:

```bash
docker build \
  -t acr10alyticsikedi.azurecr.io/10alytics-app:${GITHUB_SHA} \
  -t acr10alyticsikedi.azurecr.io/10alytics-app:latest \
  .
```

---

# 29. Pipeline Stage 6: Push Image to ACR

GitHub Actions authenticates to Azure Container Registry using Azure identity and RBAC.

The images are pushed using:

```bash
docker push acr10alyticsikedi.azurecr.io/10alytics-app:${GITHUB_SHA}
```

and:

```bash
docker push acr10alyticsikedi.azurecr.io/10alytics-app:latest
```

The GitHub Actions identity has the:

```text
AcrPush
```

role on the registry.

---

# 30. Pipeline Stage 7: Application Deployment

The deployment stage uses Azure VM Run Command.

This avoids requiring an open SSH port for CI/CD.

The pipeline instructs the VM to:

1. Authenticate using its managed identity.
2. Authenticate to Azure Container Registry.
3. Pull the required Docker image.
4. Stop the existing container.
5. Start the new container.
6. Wait for the application to initialise.
7. Run health checks.
8. Run readiness checks.

The container is started using:

```bash
docker run -d \
  --name 10alytics-app \
  --restart unless-stopped \
  -p 80:5000 \
  acr10alyticsikedi.azurecr.io/10alytics-app:${IMAGE_TAG}
```

---

# 31. Pipeline Stage 8: Health Validation

After deployment, the pipeline validates:

```text
/health
```

and:

```text
/health/ready
```

The checks are performed using:

```bash
curl --fail
```

with retry logic.

If the health or readiness checks fail, the pipeline reports a deployment failure.

---

# 32. Application Gateway Validation

Application Gateway forwards traffic to:

```text
10.10.1.4:80
```

The backend health probe verifies the application.

Expected result:

```text
Healthy
HTTP 200
```

The public application endpoint is:

```text
http://20.4.241.133/
```

---

# 33. End to End Deployment Flow

The complete deployment process is:

```text
Developer
    |
    | git push
    v
GitHub main
    |
    v
GitHub Actions
    |
    v
Python Tests
    |
    | Pass
    v
Terraform Format
    |
    v
Terraform Validate
    |
    v
Terraform Plan
    |
    v
Approval
    |
    v
Terraform Apply
    |
    v
Docker Build
    |
    v
Azure Container Registry
    |
    v
Azure VM
    |
    v
Docker Container
    |
    v
Health Check
    |
    v
Readiness Check
    |
    v
Application Gateway
    |
    v
End User
```

---

# 34. Manual Deployment

Although the preferred deployment mechanism is GitHub Actions, the infrastructure can be deployed manually.

From:

```text
terraform/
```

run:

```powershell
terraform init
terraform fmt -check
terraform validate
terraform plan
terraform apply
```

The application can then be built:

```powershell
docker build -t 10alytics-app:local .
```

For production style deployments, the GitHub Actions pipeline should be used because it provides testing, approval, traceability and automated deployment.

---

# 35. Deployment Verification

After deployment, verify the following.

## Application Gateway

Check:

```text
http://20.4.241.133/
```

## Health

Verify:

```text
http://20.4.241.133/health
```

## Readiness

Verify:

```text
http://20.4.241.133/health/ready
```

## Azure Application Gateway Backend

Confirm that:

```text
10.10.1.4
```

is reported as:

```text
Healthy
```

with:

```text
HTTP 200
```

## Docker Container

On the VM, verify:

```bash
docker ps
```

The expected container is:

```text
10alytics-app
```

---

# 36. Deployment Evidence

The implementation has been validated through the following tests:

```text
Application Tests
    |
    +-- 3 pytest tests passed
    |
Docker Build
    |
    +-- Image built successfully
    |
Docker Run
    |
    +-- Container started successfully
    |
Health Check
    |
    +-- Passed
    |
Readiness Check
    |
    +-- Passed
    |
Terraform Format
    |
    +-- Passed
    |
Terraform Validate
    |
    +-- Passed
    |
Terraform Plan
    |
    +-- Passed
    |
Terraform Apply
    |
    +-- Infrastructure provisioned
    |
ACR Push
    |
    +-- Image published
    |
VM Deployment
    |
    +-- Container deployed
    |
Application Gateway
    |
    +-- Backend healthy
```

---

# 37. Reproducing the Environment

A new engineer can reproduce the environment using the following sequence:

```text
1. Clone repository
2. Configure Azure authentication
3. Configure GitHub repository variables and secrets
4. Configure GitHub Environments
5. Configure Terraform variables
6. Initialise Terraform
7. Validate Terraform
8. Generate Terraform plan
9. Approve Terraform Apply
10. Provision Azure infrastructure
11. Build Docker image
12. Push image to Azure Container Registry
13. Deploy application to Azure VM
14. Run health checks
15. Validate Application Gateway
```

The infrastructure configuration is stored in Git and therefore provides a reproducible deployment model.

---

# 38. Infrastructure Destruction

Infrastructure destruction is handled by a separate workflow:

```text
.github/workflows/destroy.yml
```

The workflow is manually triggered.

It first generates a Terraform destroy plan:

```bash
terraform plan -destroy
```

The plan is stored as an artifact.

The destroy stage then uses the protected environment:

```text
terraform-destroy
```

Approval is required before destruction proceeds.

This provides an additional safeguard against accidental deletion of Azure resources.

---

# 39. Important Security Considerations

The following files must never be committed:

```text
terraform/terraform.tfvars
```

Private SSH keys must never be committed.

Examples:

```text
*.pem
*.key
```

Terraform state must not be committed to the repository.

The `.gitignore` file excludes:

```text
.terraform/
*.tfstate
*.tfstate.*
terraform.tfvars
*.pem
*.key
.env
```

Azure credentials are managed through GitHub Secrets and OIDC rather than hard coded in the repository.

---

# 40. Deployment Summary

The deployment architecture provides a repeatable CI/CD process where:

* Source code is stored in GitHub.
* Application tests run automatically.
* Terraform validates the infrastructure.
* Terraform generates an infrastructure plan.
* Infrastructure changes require approval.
* Terraform provisions the Azure environment.
* Docker packages the application.
* Azure Container Registry stores the image.
* Azure Managed Identity authenticates the VM.
* The VM pulls the image from ACR.
* The application is deployed automatically.
* Health and readiness checks validate the deployment.
* Application Gateway provides the public entry point.
* Docker images are tagged using Git commit SHA values.
* A separate protected workflow controls infrastructure destruction.


