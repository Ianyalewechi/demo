# 10Alytics DevOps Assessment

# Architecture Documentation

## 1. Overview

This document describes the architecture of the 10Alytics DevOps assessment solution.

The solution demonstrates a complete application delivery platform covering:

* Application development
* Automated testing
* Infrastructure provisioning
* Containerisation
* Container image management
* Continuous integration
* Continuous deployment
* Infrastructure as Code
* Cloud networking
* Identity and access management
* Secrets management
* Application health validation
* Operational management
* Controlled infrastructure destruction

The application is a Python Flask web application deployed as a Docker container on an Azure Linux Virtual Machine.

The application is exposed externally through an Azure Application Gateway.

Infrastructure is provisioned using Terraform, while GitHub Actions provides the CI/CD automation.

---

# 2. Architecture Objectives

The architecture was designed around the following objectives:

1. Automate the software delivery lifecycle.
2. Provision infrastructure using Infrastructure as Code.
3. Separate infrastructure provisioning from application deployment.
4. Ensure infrastructure changes are reviewed before application.
5. Use immutable Docker image tags based on Git commits.
6. Avoid static Azure credentials in GitHub Actions.
7. Use Azure Managed Identity where possible.
8. Protect Terraform Apply and Destroy operations with approval gates.
9. Provide application health and readiness endpoints.
10. Provide a repeatable deployment process.
11. Maintain traceability between source code, infrastructure and application versions.
12. Provide a foundation that can be extended into a production grade platform.

---

# 3. High Level Architecture

The overall architecture consists of five major layers:

1. Source Control Layer
2. CI/CD Layer
3. Infrastructure Layer
4. Application Platform Layer
5. Security and Governance Layer

The high level flow is:

```text
Developer
   |
   v
GitHub Repository
   |
   v
GitHub Actions
   |
   +----------------------+
   |                      |
   v                      v
Automated Tests       Terraform Plan
                           |
                           v
                    Approval Gate
                           |
                           v
                    Terraform Apply
                           |
                           v
                Azure Infrastructure
                           |
                           v
                    Docker Build
                           |
                           v
              Azure Container Registry
                           |
                           v
                  Azure VM Run Command
                           |
                           v
                    Docker Container
                           |
                           v
                 Flask Web Application
                           |
                           v
                 Application Gateway
                           |
                           v
                     End User
```

---

# 4. End to End Architecture

The application follows the architecture below:

```text
                         INTERNET
                            |
                            |
                            v
              +--------------------------+
              | Azure Application Gateway|
              |       Standard V2        |
              |                          |
              | Public IP: 20.4.241.133  |
              +------------+-------------+
                           |
                           |
                           | HTTP :80
                           |
                           v
              +--------------------------+
              |       Azure VNet         |
              |     vnet-10alytics       |
              |                          |
              |  +--------------------+  |
              |  | Application VM     |  |
              |  | vm-10alytics       |  |
              |  | Private IP         |  |
              |  | 10.10.1.4          |  |
              |  +---------+----------+  |
              |            |             |
              +------------|-------------+
                           |
                           | Port 80
                           v
                +----------------------+
                | Docker Container     |
                | 10alytics-app        |
                |                      |
                | Container Port 5000  |
                | Host Port 80         |
                +----------+-----------+
                           |
                           v
                +----------------------+
                | Python Flask App     |
                |                      |
                | HTML Frontend        |
                | REST API             |
                | Health Endpoints     |
                +----------------------+
```

The Application Gateway is the intended public application entry point.

The VM is not exposed through an open public application port. Direct public SSH is not available under the current network policy.

---

# 5. Source Control Architecture

The source code is hosted in GitHub.

Repository:

```text
Ianyalewechi/demo
```

The `main` branch represents the deployment branch used by the CI/CD pipeline.

The repository contains:

```text
10Alytics Demo
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
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── backend.tf
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
├── docs/
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── OPERATIONS.md
│   └── SECURITY.md
│
├── Dockerfile
├── .dockerignore
└── README.md
```

---

# 6. CI/CD Architecture

GitHub Actions is responsible for automating the application delivery process.

The pipeline is divided into the following stages:

```text
Code Commit
    |
    v
Application Tests
    |
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
Push Image to ACR
    |
    v
Deploy to Azure VM
    |
    v
Health Check
    |
    v
Release Complete
```

The pipeline ensures that infrastructure is provisioned or updated before the application deployment takes place.

---

# 7. CI/CD Job Structure

The main workflow contains the following jobs:

```text
test
  |
  v
terraform-plan
  |
  v
terraform-apply
  |
  v
build
  |
  v
deploy
  |
  v
health-check
```

## Test

The test stage:

* Checks out the repository
* Installs Python
* Installs application dependencies
* Executes pytest
* Prevents subsequent deployment stages if tests fail

The current application test suite successfully validates the Flask application.

Example result:

```text
3 passed
```

---

## Terraform Plan

The Terraform Plan stage:

* Authenticates to Azure using GitHub OIDC
* Initialises Terraform
* Checks Terraform formatting
* Validates the Terraform configuration
* Generates an execution plan
* Stores the plan as a GitHub Actions artifact

No infrastructure changes are made during this stage.

---

## Terraform Apply

Terraform Apply is protected using the GitHub environment:

```text
terraform-apply
```

The environment provides an approval gate before infrastructure changes are executed.

The approved Terraform plan is then applied.

This provides separation between:

```text
Plan
```

and

```text
Apply
```

---

## Build

After successful infrastructure provisioning, the pipeline:

1. Authenticates to Azure.
2. Authenticates to Azure Container Registry.
3. Builds the Docker image.
4. Tags the image with the Git commit SHA.
5. Tags the image as `latest`.
6. Pushes both tags to ACR.

Example image:

```text
acr10alyticsikedi.azurecr.io/10alytics-app:<commit-sha>
```

---

## Deploy

The deployment stage uses Azure VM Run Command.

The pipeline does not require direct SSH access to the VM.

The deployment process:

```text
GitHub Actions
      |
      v
Azure VM Run Command
      |
      v
VM Managed Identity
      |
      v
Azure Container Registry
      |
      v
Docker Pull
      |
      v
Docker Run
      |
      v
Application
```

The VM authenticates to Azure Container Registry using its Managed Identity.

---

## Health Check

After deployment, the pipeline validates:

```text
/health
```

and:

```text
/health/ready
```

The deployment is considered successful only when these endpoints respond successfully.

---

# 8. Application Architecture

The application is implemented using Python Flask.

The application contains:

```text
Frontend
   |
   +-- HTML
   +-- CSS
   +-- JavaScript
   |
   v
Flask Application
   |
   +-- Web Routes
   +-- API Routes
   +-- Health Endpoint
   +-- Readiness Endpoint
```

The Flask application is packaged into a Docker image.

The container listens on:

```text
5000
```

The VM exposes the application through:

```text
80
```

The Docker port mapping is:

```text
Host Port 80
      |
      v
Container Port 5000
```

---

# 9. Application Endpoints

The application provides the following endpoints.

## Application

```text
/
```

Provides the main application interface.

## Application Information

```text
/api/info
```

Returns application information including:

* Application name
* Environment
* Status
* Version

Example:

```json
{
  "application": "10Alytics Learning Platform",
  "environment": "Azure",
  "status": "running",
  "version": "2.0.0"
}
```

## Health

```text
/health
```

Used to determine whether the application is running.

## Readiness

```text
/health/ready
```

Used to determine whether the application is ready to receive traffic.

---

# 10. Container Architecture

Docker is used to package the application and its runtime dependencies.

The container provides a consistent runtime between:

```text
Developer Environment
        |
        v
CI Environment
        |
        v
Azure VM
```

The deployment container is:

```text
10alytics-app
```

The container uses:

```text
--restart unless-stopped
```

This allows Docker to automatically restart the application after an unexpected container or VM restart.

---

# 11. Azure Infrastructure Architecture

The Azure environment is deployed in:

```text
Resource Group:
rg-10alytics-devops
```

Location:

```text
West Europe
```

The major infrastructure components are:

```text
Azure
|
+-- Resource Group
|
+-- Virtual Network
|   |
|   +-- Application Gateway Subnet
|   |
|   +-- Application VM Subnet
|
+-- Application Gateway
|
+-- Linux Virtual Machine
|
+-- Network Interface
|
+-- Network Security Group
|
+-- Public IP
|
+-- Azure Container Registry
|
+-- Key Vault
|
+-- Managed Identities
|
+-- Terraform State Storage
```

---

# 12. Azure Virtual Network

The application network is:

```text
vnet-10alytics
```

The virtual network provides network isolation for the application infrastructure.

The architecture uses two main subnets.

## Application VM Subnet

```text
snet-10alytics
```

Address range:

```text
10.10.1.0/24
```

The application VM is located in this subnet.

## Application Gateway Subnet

```text
snet-appgateway
```

Address range:

```text
10.10.2.0/24
```

The Application Gateway is deployed into this subnet.

---

# 13. Application Gateway Architecture

The Application Gateway is:

```text
agw-10alytics
```

SKU:

```text
Standard V2
```

The Application Gateway provides the public entry point for the application.

Public IP:

```text
20.4.241.133
```

The Application Gateway configuration contains:

```text
Frontend
   |
   v
Listener
   |
   v
Routing Rule
   |
   v
Backend Pool
   |
   v
Backend HTTP Settings
   |
   v
VM Private IP
```

Backend target:

```text
10.10.1.4
```

Backend port:

```text
80
```

The Application Gateway performs health monitoring against the backend.

Current backend health:

```text
Healthy
```

The backend returns:

```text
HTTP 200
```

---

# 14. Network Traffic Flow

External application traffic follows this path:

```text
Internet
   |
   v
Application Gateway Public IP
20.4.241.133
   |
   v
Application Gateway Listener
   |
   v
Routing Rule
   |
   v
Backend Pool
   |
   v
10.10.1.4:80
   |
   v
Docker
   |
   v
10alytics-app:5000
   |
   v
Flask
```

This separates the public application endpoint from the application workload.

---

# 15. Azure Linux Virtual Machine

The application workload runs on:

```text
vm-10alytics
```

Operating system:

```text
Ubuntu 24.04 LTS
```

Administrative user:

```text
azureuser
```

The VM does not use password based SSH authentication.

Terraform configures:

```text
disable_password_authentication = true
```

SSH access is based on an SSH public key.

The VM has:

```text
Private IP:
10.10.1.4
```

The VM also has an Azure public IP resource associated with its network interface, although direct public SSH is not available under the current network policy.

The Application Gateway remains the intended public application entry point.

---

# 16. Azure Container Registry

The container registry is:

```text
acr10alyticsikedi
```

Login server:

```text
acr10alyticsikedi.azurecr.io
```

The registry stores Docker images produced by the CI/CD pipeline.

Example:

```text
acr10alyticsikedi.azurecr.io/10alytics-app:<commit-sha>
```

ACR administrator authentication is disabled.

```text
admin_enabled = false
```

Authentication is performed using Azure identity and RBAC.

---

# 17. Container Image Flow

The image lifecycle is:

```text
Developer
   |
   v
GitHub
   |
   v
GitHub Actions
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
Docker Pull
   |
   v
Docker Container
```

Images are tagged using the GitHub commit SHA.

This provides traceability between:

```text
Source Code
     |
     v
Git Commit
     |
     v
Docker Image
     |
     v
Running Container
```

---

# 18. Identity Architecture

The architecture uses Azure Managed Identities.

Two identities are used.

## GitHub Actions Identity

```text
id-10alytics-github-actions
```

This identity is used by GitHub Actions to authenticate to Azure.

Authentication is based on:

```text
GitHub OIDC
```

No long lived Azure client secret is required.

---

## VM Managed Identity

```text
id-10alytics-vm
```

This identity is assigned to the Azure VM.

It allows the VM to authenticate to Azure services without storing credentials on the VM.

The VM identity is used primarily for:

```text
Azure Container Registry
```

---

# 19. GitHub OIDC Architecture

The authentication flow is:

```text
GitHub Actions
      |
      v
GitHub OIDC Token
      |
      v
Azure Entra ID
      |
      v
Federated Identity Credential
      |
      v
User Assigned Managed Identity
      |
      v
Azure RBAC
      |
      v
Azure Resources
```

This removes the requirement to store an Azure client secret inside GitHub.

Separate federated credentials are used for protected workflow environments.

---

# 20. Key Vault Architecture

The solution includes:

```text
kv10demo
```

Azure Key Vault is configured with:

```text
RBAC Authorization
```

The architecture allows applications and automation to retrieve secrets without embedding them directly in source code.

The GitHub Actions identity has:

```text
Key Vault Secrets Officer
```

The VM Managed Identity has:

```text
Key Vault Secrets User
```

The Key Vault therefore provides a centralised location for future application secrets and credentials.

---

# 21. Terraform Architecture

Terraform is used as the Infrastructure as Code platform.

Terraform manages resources including:

```text
Virtual Network
Subnet
Network Security Group
Public IP
Network Interface
Virtual Machine
Managed Identity
Azure Container Registry
Key Vault
RBAC Assignments
```

The infrastructure configuration is maintained in:

```text
terraform/
```

The main Terraform files are:

```text
terraform/
|
+-- main.tf
+-- variables.tf
+-- providers.tf
+-- backend.tf
+-- identity.tf
+-- network.tf
+-- vm.tf
+-- acr.tf
+-- keyvault.tf
+-- outputs.tf
```

---

# 22. Terraform State Architecture

Terraform state is stored remotely in Azure Storage.

Storage account:

```text
st10alyticstfstate
```

Container:

```text
tfstate
```

State key:

```text
10alytics.tfstate
```

The remote state architecture provides a central source of truth for Terraform.

The backend uses Azure AD authentication:

```hcl
use_azuread_auth = true
```

This avoids embedding storage access keys into the Terraform configuration.

---

# 23. Infrastructure Provisioning Flow

Infrastructure provisioning follows:

```text
Terraform Configuration
        |
        v
Terraform Init
        |
        v
Terraform Format Check
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
Azure Resources
```

This provides controlled infrastructure changes.

---

# 24. Security Architecture

Security is applied across the architecture.

The main controls include:

```text
GitHub OIDC
      |
      v
Azure RBAC
      |
      +---- Managed Identity
      |
      +---- Key Vault
      |
      +---- ACR
      |
      +---- Terraform State
      |
      v
Network Security
      |
      +---- NSG
      |
      +---- Application Gateway
      |
      v
Application Security
      |
      +---- Docker
      +---- Health Checks
      +---- SSH Key Authentication
      +---- Password Authentication Disabled
```

The complete security design is documented separately in:

```text
docs/SECURITY.md
```

---

# 25. Governance Architecture

The architecture incorporates governance controls through the CI/CD process.

Infrastructure changes are controlled using:

```text
Terraform Plan
      |
      v
Approval
      |
      v
Terraform Apply
```

Infrastructure destruction follows a separate workflow:

```text
Terraform Destroy Plan
      |
      v
Approval
      |
      v
Terraform Destroy
```

The GitHub environments are:

```text
terraform-apply
terraform-destroy
```

This provides an approval boundary around high impact infrastructure operations.

---

# 26. Application Traceability

Each Docker image is associated with the Git commit that produced it.

Example:

```text
Git Commit
     |
     v
GitHub Actions
     |
     v
Docker Image
     |
     v
ACR
     |
     v
Azure VM
     |
     v
Running Application
```

The image
