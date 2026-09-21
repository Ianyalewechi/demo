# 10Alytics DevOps Assessment

## Complete CI/CD Pipeline, Infrastructure as Code and Azure Deployment

---

# 1. Overview

This project implements a complete DevOps delivery platform for a Python Flask web application.

The solution demonstrates how application source code can move from a developer commit through automated testing, infrastructure provisioning, containerisation, deployment and application health validation.

The platform combines:

* GitHub
* GitHub Actions
* Python Flask
* Docker
* Terraform
* Microsoft Azure
* Azure Virtual Machine
* Azure Application Gateway
* Azure Container Registry
* Azure Key Vault
* Azure Managed Identity
* Azure RBAC
* GitHub OIDC

The implementation was designed to satisfy the 10Alytics DevOps assessment requirements while demonstrating practical DevOps, cloud infrastructure, security and operational principles.

---

# 2. Assessment Requirements

The assessment requires a complete CI/CD pipeline for a sample web application.

The solution must automatically:

1. Build the application.
2. Run automated tests.
3. Deploy the application.
4. Deploy to AWS, Azure or a Docker environment.
5. Use GitHub Actions or Jenkins.
6. Use Terraform or Ansible to provision infrastructure.
7. Document the deployment process.
8. Demonstrate the pipeline flow.
9. Explain the technology choices.
10. Explain how another person can replicate and extend the solution.

This implementation addresses all of these requirements.

---

# 3. Solution Summary

The solution uses GitHub Actions as the CI/CD platform and Terraform as the Infrastructure as Code platform.

The application is packaged as a Docker container and stored in Azure Container Registry.

The container is deployed to an Azure Linux Virtual Machine.

Azure Application Gateway provides the intended public application entry point.

The complete delivery process is:

```text
Developer
    |
    v
GitHub Repository
    |
    v
GitHub Actions
    |
    v
Automated Tests
    |
    v
Terraform Validation
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
Azure Infrastructure
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
Flask Application
    |
    v
Application Gateway
    |
    v
End User
```

---

# 4. Live Application

The application is exposed through the Azure Application Gateway.

Application Gateway public endpoint:

```text
20.4.241.133
```

Application:

```text
http://20.4.241.133/
```

Health endpoint:

```text
http://20.4.241.133/health
```

Readiness endpoint:

```text
http://20.4.241.133/health/ready
```

Application information endpoint:

```text
http://20.4.241.133/api/info
```

The Application Gateway is the intended public entry point for the application.

---

# 5. Architecture

The high level architecture is:

```text
                         INTERNET
                            |
                            v
              +--------------------------+
              | Azure Application Gateway|
              |       Standard V2        |
              |                          |
              | Public IP: 20.4.241.133  |
              +------------+-------------+
                           |
                           | HTTP :80
                           v
              +--------------------------+
              |       Azure VNet         |
              |     vnet-10alytics       |
              |                          |
              |  +--------------------+  |
              |  | Azure Linux VM      |  |
              |  | vm-10alytics       |  |
              |  | 10.10.1.4          |  |
              |  +---------+----------+  |
              |            |
              +------------|-------------+
                           |
                           | Port 80
                           v
                +----------------------+
                | Docker Container     |
                | 10alytics-app        |
                |                      |
                | Container Port 5000  |
                +----------+-----------+
                           |
                           v
                +----------------------+
                | Python Flask App     |
                |                      |
                | Web UI               |
                | REST API             |
                | Health Checks        |
                +----------------------+
```

The detailed architecture is documented in:

```text
docs/ARCHITECTURE.md
```

---

# 6. CI/CD Pipeline

The GitHub Actions pipeline consists of the following stages:

```text
Code Commit
     |
     v
Test Flask Application
     |
     v
Terraform Plan
     |
     v
Terraform Apply Approval
     |
     v
Terraform Apply
     |
     v
Build Docker Image
     |
     v
Push Image to ACR
     |
     v
Deploy Application
     |
     v
Health Check
     |
     v
Release Complete
```

The pipeline is implemented in:

```text
.github/workflows/ci-cd.yml
```

---

# 7. CI/CD Pipeline Jobs

## Test

The test job:

* Checks out the source code.
* Installs Python 3.11.
* Installs application dependencies.
* Executes pytest.
* Stops the pipeline if tests fail.

Current test result:

```text
3 passed
```

---

## Terraform Plan

The Terraform Plan job:

* Authenticates to Azure using GitHub OIDC.
* Initialises Terraform.
* Checks Terraform formatting.
* Validates the Terraform configuration.
* Generates a Terraform execution plan.
* Stores the plan as a workflow artifact.

No infrastructure changes are made during this stage.

---

## Terraform Apply

Terraform Apply is protected using the GitHub environment:

```text
terraform-apply
```

The workflow pauses for approval before infrastructure changes are applied.

This creates a controlled boundary between:

```text
Terraform Plan
```

and:

```text
Terraform Apply
```

---

## Build

After successful infrastructure provisioning, GitHub Actions:

1. Authenticates to Azure.
2. Authenticates to Azure Container Registry.
3. Builds the Docker image.
4. Tags the image using the Git commit SHA.
5. Tags the image as `latest`.
6. Pushes the images to ACR.

Example:

```text
acr10alyticsikedi.azurecr.io/10alytics-app:<commit-sha>
```

---

## Deploy

The deployment job uses Azure VM Run Command.

The pipeline does not depend on direct SSH access to the VM.

The deployment process is:

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
```

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

The deployment is considered successful only when the health checks complete successfully.

---

# 8. Technology Stack

| Layer                  | Technology                |
| ---------------------- | ------------------------- |
| Application            | Python Flask              |
| Frontend               | HTML, CSS, JavaScript     |
| Testing                | Pytest                    |
| Source Control         | GitHub                    |
| CI/CD                  | GitHub Actions            |
| Containerisation       | Docker                    |
| Container Registry     | Azure Container Registry  |
| Infrastructure as Code | Terraform                 |
| Cloud Platform         | Microsoft Azure           |
| Compute                | Azure Linux VM            |
| Public Entry Point     | Azure Application Gateway |
| Secrets Management     | Azure Key Vault           |
| Authentication         | GitHub OIDC               |
| Identity               | Azure Managed Identity    |
| Access Control         | Azure RBAC                |
| Network                | Azure Virtual Network     |
| Network Security       | Azure NSG                 |
| Terraform State        | Azure Storage             |

---

# 9. Application

The application is a Python Flask based learning platform.

The application provides:

```text
/
```

for the main web interface.

Application information:

```text
/api/info
```

Health:

```text
/health
```

Readiness:

```text
/health/ready
```

Example application information response:

```json
{
  "application": "10Alytics Learning Platform",
  "environment": "Azure",
  "status": "running",
  "version": "2.0.0"
}
```

---

# 10. Docker Architecture

The application is packaged into a Docker image.

The container:

```text
10alytics-app
```

runs the Flask application on:

```text
5000
```

The Azure VM maps:

```text
Host Port 80
      |
      v
Container Port 5000
```

The container uses:

```text
--restart unless-stopped
```

This allows the application container to restart automatically following a container or VM restart.

---

# 11. Azure Infrastructure

The Azure infrastructure is deployed into:

```text
Resource Group:
rg-10alytics-devops
```

Location:

```text
West Europe
```

Main resources:

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
+-- agw-10alytics
|
+-- acr10alyticsikedi
|
+-- kv10demo
|
+-- id-10alytics-github-actions
|
+-- id-10alytics-vm
|
+-- Terraform State Storage
```

All infrastructure is defined using Terraform.

---

# 12. Network Architecture

The virtual network is:

```text
vnet-10alytics
```

The application VM is located in:

```text
snet-10alytics
```

with address range:

```text
10.10.1.0/24
```

The Application Gateway is located in:

```text
snet-appgateway
```

with address range:

```text
10.10.2.0/24
```

Application traffic flows through:

```text
Internet
   |
   v
Application Gateway
   |
   v
VM
   |
   v
Docker
   |
   v
Flask
```

The Application Gateway is the intended public application entry point.

---

# 13. Infrastructure as Code

Terraform manages the Azure infrastructure.

Terraform configuration is stored in:

```text
terraform/
```

The configuration includes:

```text
main.tf
providers.tf
backend.tf
variables.tf
outputs.tf
identity.tf
network.tf
vm.tf
acr.tf
keyvault.tf
```

Terraform provides:

* Repeatable infrastructure provisioning.
* Infrastructure version control.
* Change planning.
* Infrastructure validation.
* Controlled infrastructure changes.
* Remote state management.

---

# 14. Terraform Remote State

Terraform state is stored remotely in Azure Storage.

Storage account:

```text
st10alyticstfstate
```

Container:

```text
tfstate
```

State file:

```text
10alytics.tfstate
```

The Terraform backend uses Azure AD authentication rather than embedding storage access keys in the Terraform configuration.

---

# 15. Security Architecture

Security is incorporated across the application and infrastructure.

The solution uses:

* GitHub OIDC
* Azure Managed Identity
* Azure RBAC
* Azure Key Vault
* SSH key authentication
* Password authentication disabled
* Azure NSG
* Application Gateway
* ACR admin authentication disabled
* GitHub protected environments
* Remote Terraform state
* Commit based Docker image tags

Detailed security documentation is available in:

```text
docs/SECURITY.md
```

---

# 16. Identity and Access Management

The solution uses two primary Azure identities.

## GitHub Actions Identity

```text
id-10alytics-github-actions
```

Used by GitHub Actions to authenticate to Azure through OIDC.

## VM Managed Identity

```text
id-10alytics-vm
```

Used by the Azure VM to authenticate to Azure services.

The architecture therefore avoids storing long lived Azure credentials in the application or VM.

---

# 17. Container Registry Security

Azure Container Registry:

```text
acr10alyticsikedi
```

stores the application Docker images.

ACR administrator authentication is disabled.

Access is controlled using Azure RBAC.

GitHub Actions requires permission to push images.

The VM requires permission to pull images.

This provides separation between:

```text
Image Publisher
```

and:

```text
Image Consumer
```

---

# 18. Key Vault

Azure Key Vault:

```text
kv10demo
```

is included for centralised secrets management.

Key Vault uses Azure RBAC.

The architecture allows application and infrastructure secrets to be managed outside source code.

This provides a foundation for securely integrating future application credentials, API keys and other secrets.

---

# 19. Approval and Governance

Infrastructure provisioning is protected using:

```text
terraform-apply
```

Infrastructure destruction is protected using:

```text
terraform-destroy
```

Normal deployment therefore follows:

```text
Plan
  |
  v
Approval
  |
  v
Apply
```

Destruction follows:

```text
Destroy Plan
  |
  v
Approval
  |
  v
Destroy
```

This reduces the risk of accidental infrastructure changes or destruction.

---

# 20. Infrastructure Destruction

Infrastructure destruction is implemented as a separate manually triggered workflow.

Workflow:

```text
.github/workflows/destroy.yml
```

The process is:

```text
Manual Trigger
      |
      v
Terraform Destroy Plan
      |
      v
Review
      |
      v
Approval
      |
      v
Terraform Destroy
```

The destroy workflow is not triggered by normal application deployments.

---

# 21. Rollback

Docker images are tagged using Git commit SHA values.

Example:

```text
10alytics-app:abc123
```

This allows previously deployed application versions to be identified.

The current implementation provides manual application rollback.

Rollback involves:

```text
Identify Previous Good Commit
          |
          v
Identify Docker Image
          |
          v
Pull Image from ACR
          |
          v
Restart Container
          |
          v
Health Check
```

Automated rollback is a future enhancement.

---

# 22. Repository Structure

The repository is organised as follows:

```text
demo/
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
│   ├── providers.tf
│   ├── backend.tf
│   ├── identity.tf
│   ├── network.tf
│   ├── vm.tf
│   ├── acr.tf
│   ├── keyvault.tf
│   └── outputs.tf
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
├── .gitignore
└── README.md
```

---

# 23. Documentation

Detailed documentation is separated into four areas.

## Architecture

```text
docs/ARCHITECTURE.md
```

Contains:

* Solution architecture
* Azure architecture
* Network architecture
* CI/CD architecture
* Identity architecture
* Container architecture
* Infrastructure architecture
* Design decisions
* Future enhancements

---

## Deployment

```text
docs/DEPLOYMENT.md
```

Contains:

* Prerequisites
* Local setup
* Testing
* Docker setup
* Azure authentication
* Terraform setup
* GitHub configuration
* CI/CD deployment
* Application verification
* Infrastructure destruction

---

## Operations

```text
docs/OPERATIONS.md
```

Contains:

* Application operations
* Health checks
* VM operations
* Docker operations
* Application Gateway operations
* Monitoring
* Troubleshooting
* Incident response
* Rollback
* Maintenance

---

## Security

```text
docs/SECURITY.md
```

Contains:

* Identity and access management
* GitHub OIDC
* Azure RBAC
* Managed Identity
* Key Vault
* Network security
* Container security
* CI/CD security
* Terraform security
* Incident response
* Security improvements

---

# 24. Local Development

Clone the repository:

```bash
git clone <repository-url>
cd demo
```

Create a Python virtual environment:

```bash
python -m venv venv
```

Activate the environment on Windows:

```powershell
.\venv\Scripts\Activate.ps1
```

Install dependencies:

```bash
cd app
python -m pip install -r requirements.txt
```

Run the tests:

```bash
python -m pytest -v
```

Run the application:

```bash
python application.py
```

The application will be available locally on:

```text
http://127.0.0.1:5000/
```

---

# 25. Docker Deployment

Build the Docker image:

```bash
docker build -t 10alytics-app .
```

Run the container:

```bash
docker run -d \
  --name 10alytics-app \
  -p 5000:5000 \
  10alytics-app
```

Verify:

```text
http://localhost:5000/
```

Health:

```text
http://localhost:5000/health
```

Readiness:

```text
http://localhost:5000/health/ready
```

---

# 26. Terraform Deployment

Terraform is located in:

```text
terraform/
```

Initialise Terraform:

```bash
terraform init
```

Format the configuration:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Create a plan:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

For the assessment workflow, Terraform Apply is normally executed through the protected GitHub Actions environment.

---

# 27. GitHub Actions

The main CI/CD workflow is:

```text
.github/workflows/ci-cd.yml
```

The infrastructure destruction workflow is:

```text
.github/workflows/destroy.yml
```

The main workflow runs automatically when code is pushed to:

```text
main
```

It can also be manually triggered using GitHub Actions.

---

# 28. GitHub Configuration

The CI/CD pipeline requires Azure authentication configuration.

GitHub Actions uses:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
```

The repository also uses variables for environment configuration.

Examples include:

```text
AZURE_RESOURCE_GROUP
AZURE_LOCATION
ACR_NAME
VM_NAME
KEY_VAULT_NAME
```

Azure authentication uses GitHub OIDC rather than storing an Azure client secret.

---

# 29. Application Validation

The deployed application can be validated using:

```text
/
```

```text
/health
```

```text
/health/ready
```

```text
/api/info
```

The Application Gateway backend health should report:

```text
Healthy
```

with:

```text
HTTP 200
```

This confirms the traffic path:

```text
Application Gateway
        |
        v
Azure VM
        |
        v
Docker
        |
        v
Flask Application
```

is functioning correctly.

---

# 30. Assessment Mapping

| Assessment Requirement     | Implementation                                 |
| -------------------------- | ---------------------------------------------- |
| Web Application            | Python Flask                                   |
| Automated Build            | Docker Build                                   |
| Automated Testing          | Pytest                                         |
| CI/CD                      | GitHub Actions                                 |
| Cloud Deployment           | Microsoft Azure                                |
| Infrastructure as Code     | Terraform                                      |
| Containerisation           | Docker                                         |
| Container Registry         | Azure Container Registry                       |
| Infrastructure Approval    | GitHub Environment                             |
| Infrastructure Destruction | Protected Terraform Destroy                    |
| Health Validation          | `/health`                                      |
| Readiness Validation       | `/health/ready`                                |
| Security                   | OIDC, RBAC, Managed Identity, Key Vault        |
| Documentation              | Architecture, Deployment, Operations, Security |

---

# 31. Six Dimensional Assessment Mapping

## Governance

Implemented through:

* Terraform Plan
* Terraform Apply approval
* Terraform Destroy approval
* Git history
* GitHub Actions audit trail
* Azure RBAC
* Remote Terraform state

## People

The solution supports roles including:

* Developer
* QA
* DevOps Engineer
* Cloud Engineer
* Security Engineer
* Infrastructure Engineer
* Operations
* Application Owner
* Approver

## Functional Process

```text
Develop
  |
Commit
  |
Test
  |
Validate
  |
Plan
  |
Approve
  |
Provision
  |
Build
  |
Publish
  |
Deploy
  |
Validate
  |
Release
```

## Technology

The solution uses:

* Python
* Flask
* GitHub
* GitHub Actions
* Terraform
* Docker
* Azure
* ACR
* Application Gateway
* Key Vault
* Managed Identity
* RBAC

## Service Delivery

The solution provides:

* Automated testing
* Automated infrastructure validation
* Controlled infrastructure provisioning
* Automated Docker build
* Automated image publication
* Automated deployment
* Health validation
* Version traceability
* Repeatable deployment

## Performance and Insights

The current solution provides:

* Application health checks
* Application readiness checks
* Application Gateway backend health
* Docker container status
* Azure resource status
* GitHub Actions execution history

Future enhancements include Azure Monitor, Application Insights, Log Analytics and centralised observability.

---

# 32. Security Principles

The solution follows several security principles.

## Least Privilege

Azure identities are assigned only the roles required for their responsibilities.

## No Long Lived Azure Credentials

GitHub Actions uses OIDC.

## Managed Identity

The Azure VM uses Managed Identity to authenticate to Azure services.

## Secrets Management

Azure Key Vault is provided for centralised secrets management.

## Network Segmentation

The VM and Application Gateway are deployed in separate subnets.

## Controlled Infrastructure Changes

Terraform Apply and Destroy operations require approval.

## Immutable Application Versioning

Docker images are tagged using Git commit SHA values.

---

# 33. Operational Model

The operational lifecycle is:

```text
Deploy
   |
   v
Health Check
   |
   v
Monitor
   |
   v
Troubleshoot
   |
   v
Rollback if Required
   |
   v
Maintain
```

Operational procedures are documented in:

```text
docs/OPERATIONS.md
```

---

# 34. Future Enhancements

The current implementation provides a complete assessment solution.

Potential future enhancements include:

## Application Platform

* Azure Container Apps
* Azure Kubernetes Service
* Horizontal scaling
* Autoscaling

## Security

* Web Application Firewall
* Microsoft Defender for Cloud
* Container vulnerability scanning
* SAST
* SCA
* DAST
* Infrastructure security scanning
* Runtime container security

## Observability

* Azure Monitor
* Application Insights
* Log Analytics
* Centralised logging
* Metrics
* Distributed tracing
* Alerting

## Deployment

* Blue green deployment
* Canary deployment
* Automated rollback
* Staging environment
* Production environment
* Release promotion

## Resilience

* Availability zones
* Disaster recovery
* Automated backups
* Managed database
* Private endpoints

---

# 35. 30 Minute Teaching Session

The solution can be presented using the following structure.

## 0 to 5 Minutes: Business and Technical Overview

Explain:

* The assessment objective.
* The application.
* The architecture.
* The cloud platform.
* The reason for using CI/CD.

---

## 5 to 10 Minutes: Architecture

Demonstrate:

```text
GitHub
   |
GitHub Actions
   |
Terraform
   |
Azure
   |
Application Gateway
   |
VM
   |
Docker
   |
Flask
```

Explain the role of each component.

---

## 10 to 17 Minutes: CI/CD Pipeline

Walk through:

```text
Commit
   |
Test
   |
Terraform Plan
   |
Approval
   |
Terraform Apply
   |
Docker Build
   |
ACR Push
   |
Deployment
   |
Health Check
```

Show the GitHub Actions workflow.

---

## 17 to 22 Minutes: Security

Explain:

* GitHub OIDC
* Azure Managed Identity
* RBAC
* Key Vault
* SSH keys
* NSG
* ACR authentication
* Protected Terraform environments

---

## 22 to 26 Minutes: Live Demonstration

Demonstrate:

1. Application running.
2. GitHub Actions workflow.
3. Terraform plan.
4. Approval gate.
5. Docker image in ACR.
6. Application deployment.
7. Health check.
8. Application Gateway backend health.

---

## 26 to 30 Minutes: Replication and Extension

Explain how another engineer can:

1. Clone the repository.
2. Configure Azure credentials.
3. Configure GitHub variables and secrets.
4. Initialise Terraform.
5. Provision infrastructure.
6. Run the application.
7. Trigger the CI/CD pipeline.
8. Extend the infrastructure or application.

---

# 36. Key Architecture Decisions

The main architecture decisions are:

| Decision               | Reason                                   |
| ---------------------- | ---------------------------------------- |
| GitHub Actions         | Native GitHub CI/CD integration          |
| Terraform              | Infrastructure as Code                   |
| Docker                 | Consistent application packaging         |
| Azure VM               | Simple and transparent container runtime |
| ACR                    | Managed Azure container registry         |
| Application Gateway    | Public application entry point           |
| OIDC                   | Secure GitHub to Azure authentication    |
| Managed Identity       | Avoid credentials on Azure VM            |
| Key Vault              | Centralised secrets management           |
| Protected Environments | Controlled infrastructure changes        |
| Commit SHA Images      | Application traceability                 |

---

# 37. Project Outcomes

The implementation demonstrates:

```text
Application Development
        +
Automated Testing
        +
Infrastructure as Code
        +
Cloud Provisioning
        +
Containerisation
        +
Container Registry
        +
CI/CD
        +
Security
        +
Governance
        +
Operational Validation
```

The result is a repeatable DevOps platform capable of taking an application from source code to a running Azure environment through an automated and controlled delivery process.

---

# 38. Related Documentation

For detailed architecture:

```text
docs/ARCHITECTURE.md
```

For deployment and replication:

```text
docs/DEPLOYMENT.md
```

For operational procedures:

```text
docs/OPERATIONS.md
```

For security:

```text
docs/SECURITY.md
```

---

# 39. Conclusion

The 10Alytics DevOps assessment solution provides a complete example of modern application delivery using GitHub, GitHub Actions, Terraform, Docker and Microsoft Azure.

The architecture provides:

* Automated testing
* Infrastructure as Code
* Controlled infrastructure provisioning
* Containerised application deployment
* Azure Container Registry
* Application Gateway
* Managed Identity
* GitHub OIDC
* Key Vault
* RBAC
* Health and readiness validation
* Deployment traceability
* Protected infrastructure destruction
* Operational documentation

The platform is designed to be repeatable, auditable and extensible while providing a clear foundation for future production enhancements.
