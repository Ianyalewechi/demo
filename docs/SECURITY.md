# 10Alytics DevOps Assessment

# Security Documentation

## 1. Overview

Security is implemented across the application, CI/CD pipeline, Azure infrastructure, identity layer, network layer and operational processes.

The solution follows the principles of:

* Least privilege
* Passwordless authentication where possible
* Identity based access
* Separation of responsibilities
* Secure secret management
* Infrastructure as Code
* Controlled infrastructure changes
* Network segmentation
* Deployment traceability
* Protected destructive operations

The main security controls are:

```text
GitHub
   |
   | OpenID Connect
   v
Microsoft Entra ID
   |
   v
Azure Managed Identity
   |
   +----------------------+
   |                      |
   v                      v
Azure RBAC            Azure Services
   |
   +----------------------+
   |
   +--> ACR
   +--> Key Vault
   +--> Azure Infrastructure
```

---

# 2. Security Architecture

The security architecture operates across multiple layers.

```text
+---------------------------------------------------+
|                  Application Layer                |
|                                                   |
| Flask Application                                  |
| Health / Readiness Endpoints                       |
+---------------------------------------------------+
                       |
+---------------------------------------------------+
|                  Container Layer                   |
|                                                   |
| Docker                                             |
| Versioned Images                                   |
| ACR                                                |
+---------------------------------------------------+
                       |
+---------------------------------------------------+
|                  Identity Layer                    |
|                                                   |
| Microsoft Entra ID                                 |
| OIDC                                               |
| Managed Identity                                   |
| RBAC                                               |
+---------------------------------------------------+
                       |
+---------------------------------------------------+
|                  Infrastructure Layer              |
|                                                   |
| Azure VM                                           |
| Virtual Network                                    |
| Network Security Group                             |
| Application Gateway                                |
+---------------------------------------------------+
                       |
+---------------------------------------------------+
|                  Secrets Layer                     |
|                                                   |
| GitHub Secrets                                     |
| Azure Key Vault                                    |
+---------------------------------------------------+
```

---

# 3. Security Principles

The implementation follows the following security principles.

## Least Privilege

Identities receive only the permissions required to perform their responsibilities.

For example:

```text
GitHub Actions
    |
    +--> AcrPush

VM Managed Identity
    |
    +--> AcrPull
```

The VM does not receive permission to push images to ACR.

GitHub Actions does not require permission to pull application images on the VM.

---

# 4. Identity and Access Management

Azure identity management is based on Microsoft Entra ID.

The solution uses:

* Microsoft Entra ID
* User Assigned Managed Identity
* GitHub OpenID Connect
* Azure RBAC
* GitHub Secrets
* Azure Key Vault

This avoids storing long lived Azure credentials in application code.

---

# 5. GitHub Actions Authentication

GitHub Actions authenticates to Azure using OpenID Connect.

The workflow uses:

```yaml id="2xgp4n"
permissions:
  id-token: write
  contents: read
```

Azure login:

```yaml id="9d2y0d"
- name: Login to Azure using OIDC
  uses: azure/login@v3
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

This means the pipeline does not require a stored Azure client secret.

---

# 6. GitHub OIDC Flow

The authentication flow is:

```text
GitHub Actions
       |
       | OIDC Token
       v
Microsoft Entra ID
       |
       | Validate Federated Credential
       v
Azure Managed Identity
       |
       v
Azure Resource Access
```

GitHub provides an identity token for the workflow.

Microsoft Entra ID validates the token against the configured federated identity credential.

If the token matches the trusted repository, branch or environment, Azure issues an access token.

---

# 7. Federated Identity Credentials

The GitHub Actions identity is:

```text
id-10alytics-github-actions
```

The identity contains federated credentials for GitHub Actions.

The main branch credential uses:

```text
repo:Ianyalewechi@98784873/demo@1377631048:ref:refs/heads/main
```

The Terraform Apply environment uses:

```text
repo:Ianyalewechi@98784873/demo@1377631048:environment:terraform-apply
```

The environment based credential ensures that the protected Terraform Apply job can authenticate after the required approval.

---

# 8. GitHub Actions Managed Identity

The GitHub Actions identity is:

```text
id-10alytics-github-actions
```

Its purpose is to allow the CI/CD pipeline to interact with Azure without storing an Azure client secret.

The identity has the following resource group level roles:

```text
Contributor
User Access Administrator
```

It also has:

```text
Storage Blob Data Contributor
```

on the Terraform state storage account.

It has:

```text
AcrPush
```

on the Azure Container Registry.

It has:

```text
Key Vault Secrets Officer
```

on the Azure Key Vault.

---

# 9. VM Managed Identity

The Azure VM uses a separate managed identity:

```text
id-10alytics-vm
```

This identity is assigned directly to:

```text
vm-10alytics
```

The VM managed identity is used to authenticate to Azure services without storing credentials on the VM.

---

# 10. VM Authentication to ACR

The VM authenticates to Azure using its managed identity.

The deployment process uses:

```bash id="e3f8n1"
az login \
  --identity \
  --allow-no-subscriptions
```

The VM then authenticates to Azure Container Registry:

```bash id="y7q9kl"
az acr login \
  --name acr10alyticsikedi
```

The VM has:

```text
AcrPull
```

on the registry.

This allows the VM to pull images without storing an ACR administrator password.

---

# 11. Azure Container Registry Security

Azure Container Registry is:

```text
acr10alyticsikedi.azurecr.io
```

ACR administrator authentication is disabled:

```text
admin_enabled = false
```

This prevents the deployment from depending on a shared registry username and password.

Instead, access is controlled using Azure RBAC.

---

# 12. ACR Role Separation

Two identities have different responsibilities.

## GitHub Actions

Role:

```text
AcrPush
```

Purpose:

```text
Build and push Docker images
```

## Azure VM

Role:

```text
AcrPull
```

Purpose:

```text
Pull Docker images for deployment
```

This creates a clear separation:

```text
GitHub Actions
      |
      | Push
      v
Azure Container Registry
      ^
      |
      | Pull
      |
Azure VM
```

The VM cannot push application images under its assigned ACR role.

---

# 13. Azure Key Vault

Azure Key Vault is provisioned as:

```text
kv10demo
```

The Key Vault uses Azure RBAC:

```hcl id="cn5b4p"
rbac_authorization_enabled = true
```

This means access is controlled through Azure role assignments instead of Key Vault access policies.

---

# 14. Key Vault Access

The GitHub Actions identity has:

```text
Key Vault Secrets Officer
```

The VM managed identity has:

```text
Key Vault Secrets User
```

This provides different levels of access based on responsibility.

```text
GitHub Actions
       |
       | Secrets Officer
       v
   Key Vault
       ^
       |
       | Secrets User
       |
      VM
```

---

# 15. Secret Management

Secrets must not be hard coded into application source code.

The solution uses:

```text
GitHub Secrets
Azure Key Vault
```

for sensitive configuration.

Examples of sensitive information include:

* Azure subscription ID
* Azure tenant ID
* Azure client ID
* SSH public key configuration
* Application secrets
* Future database credentials
* API credentials

Private keys must never be committed to GitHub.

---

# 16. GitHub Secrets

The following repository secrets are configured:

```text
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
VM_SSH_PUBLIC_KEY
```

The values are consumed by GitHub Actions through:

```text
${{ secrets.SECRET_NAME }}
```

They are not written directly into the workflow as plaintext values.

---

# 17. GitHub Repository Variables

Non secret configuration is stored using GitHub repository variables.

Configured variables include:

```text
AZURE_RESOURCE_GROUP
AZURE_LOCATION
ACR_NAME
VM_NAME
KEY_VAULT_NAME
```

These values are referenced using:

```text
${{ vars.VARIABLE_NAME }}
```

This separates configuration from sensitive credentials.

---

# 18. Sensitive Terraform Files

The following files must not be committed:

```text
terraform/terraform.tfvars
```

The `.gitignore` configuration excludes:

```text
terraform.tfvars
*.tfvars.json
```

Terraform state files are also excluded:

```text
*.tfstate
*.tfstate.*
```

---

# 19. Terraform State Security

Terraform state is stored remotely in Azure Storage.

```text
Storage Account:
st10alyticstfstate

Container:
tfstate

State:
10alytics.tfstate
```

The backend uses Azure AD authentication:

```hcl id="v2p7x9"
use_azuread_auth = true
```

This avoids embedding storage access keys in the Terraform backend configuration.

---

# 20. SSH Security

The Azure VM is configured to use SSH key authentication.

Password authentication is disabled:

```hcl id="j6n3f4"
disable_password_authentication = true
```

The VM administrator uses:

```text
azureuser
```

and an SSH public key.

The private SSH key remains outside the repository.

Example private key location on the development machine:

```text
~/.ssh/10alytics-devops
```

The private key must never be:

* Committed to Git
* Uploaded to GitHub
* Stored in application source code
* Shared through chat
* Embedded in Terraform files

---

# 21. Network Security

The Azure environment uses a Virtual Network:

```text
vnet-10alytics
```

with:

```text
10.10.0.0/16
```

The application VM is located in:

```text
snet-10alytics
10.10.1.0/24
```

Application Gateway is located in:

```text
snet-appgateway
10.10.2.0/24
```

This provides network segmentation between the application compute layer and the public entry layer.

---

# 22. Application Gateway Security Boundary

Azure Application Gateway acts as the intended public application entry point.

```text
Internet
    |
    v
Application Gateway
    |
    v
Private VM Backend
```

The application is therefore not intended to be accessed directly through the VM public address.

Application traffic is routed through:

```text
Application Gateway
        |
        v
10.10.1.4:80
```

---

# 23. Network Security Group

A Network Security Group is associated with the VM network interface.

```text
nsg-10alytics
```

The NSG provides an additional network security control layer.

The Azure environment also enforces network policy that prevents unrestricted public inbound application access.

Direct public SSH is not available under the current network configuration.

---

# 24. Application Port Security

The application uses:

```text
VM Port: 80
Container Port: 5000
```

Traffic flow:

```text
Application Gateway
        |
        | HTTP :80
        v
Azure VM
        |
        | Docker :5000
        v
Flask Application
```

The Docker container itself is not directly exposed to the public internet.

---

# 25. CI/CD Security

The CI/CD pipeline has several security controls.

These include:

* GitHub OIDC
* Azure RBAC
* Managed Identity
* GitHub Secrets
* Protected GitHub Environments
* Terraform Plan
* Terraform Apply approval
* Version controlled workflows
* Docker image versioning
* No ACR administrator credentials
* No Azure client secret

---

# 26. Protected Terraform Apply

Infrastructure changes require a protected environment:

```text
terraform-apply
```

The pipeline sequence is:

```text
Terraform Plan
       |
       v
Approval
       |
       v
Terraform Apply
```

This prevents infrastructure changes from being applied automatically without the required approval.

---

# 27. Protected Terraform Destroy

Infrastructure destruction is separated into:

```text
.github/workflows/destroy.yml
```

The workflow is manually triggered.

It uses:

```text
terraform-destroy
```

as a protected GitHub Environment.

The process is:

```text
Destroy Plan
     |
     v
Approval
     |
     v
Destroy
```

This reduces the risk of accidental infrastructure deletion.

---

# 28. Terraform Security Controls

Terraform provides several governance and security benefits.

The pipeline executes:

```bash id="q6w7b3"
terraform fmt -check
```

then:

```bash id="t7c4ra"
terraform validate
```

then:

```bash id="b4v6cg"
terraform plan
```

Only after approval does the pipeline execute:

```bash id="g0xqks"
terraform apply
```

This provides an auditable infrastructure change process.

---

# 29. Application Image Security

Application images are stored in Azure Container Registry.

Images are tagged using the Git commit SHA:

```text id="q7u3ny"
10alytics-app:<commit-sha>
```

This provides:

* Deployment traceability
* Version identification
* Rollback capability
* Release history

The `latest` tag is also maintained for convenience, but the deployment workflow uses the immutable commit SHA tag.

---

# 30. Container Security

The application runs inside a Docker container.

The container is started with:

```bash id="2z8fmy"
docker run -d \
  --name 10alytics-app \
  --restart unless-stopped \
  -p 80:5000 \
  <image>
```

The application image should only contain the dependencies required to run the application.

The Docker build context excludes unnecessary files through:

```text
.dockerignore
```

---

# 31. Source Code Security

Source code is maintained in GitHub.

Security sensitive information must not be stored in:

* Python source code
* HTML
* JavaScript
* CSS
* Dockerfile
* Terraform configuration
* GitHub workflow files

Instead, secrets should be supplied through secure configuration mechanisms.

---

# 32. Repository Security

The repository should maintain the following controls:

```text
Source code
      |
      v
GitHub
      |
      +--> Protected main branch
      |
      +--> GitHub Actions
      |
      +--> Environment approvals
      |
      +--> Secrets
      |
      +--> Audit history
```

The `main` branch is the deployment branch.

---

# 33. Dependency Security

Python dependencies are defined in:

```text
app/requirements.txt
```

Dependencies are installed during CI using:

```bash id="rj1s7u"
python -m pip install -r requirements.txt
```

The application should periodically review dependencies for:

* Security vulnerabilities
* Unsupported versions
* Deprecated packages
* Compatibility issues

A future enhancement would be to add automated dependency scanning to the CI pipeline.

---

# 34. Docker Image Scanning

The current implementation does not include an automated container vulnerability scanning stage.

A future enhancement can add image scanning using tools such as:

* Microsoft Defender for Cloud
* Trivy
* Azure Container Registry security scanning
* GitHub Advanced Security

A recommended future pipeline would be:

```text
Docker Build
     |
     v
Image Scan
     |
     v
Security Gate
     |
     v
Push to ACR
```

---

# 35. Static Application Security Testing

The current assessment implementation focuses on functional testing and infrastructure validation.

A future enhancement can add SAST.

Example:

```text
Source Code
    |
    v
SAST
    |
    v
Dependency Scan
    |
    v
Tests
    |
    v
Terraform Security Scan
    |
    v
Docker Image Scan
    |
    v
Deployment
```

Possible tools include:

* GitHub CodeQL
* Bandit
* Semgrep
* Checkov
* Trivy

---

# 36. Infrastructure Security Scanning

Terraform configuration can be scanned for security misconfiguration.

Potential tools include:

```text
Checkov
tfsec
Terrascan
```

For example:

```text
Terraform
   |
   v
Security Scan
   |
   v
Terraform Plan
```

This can identify issues such as:

* Publicly exposed resources
* Weak network controls
* Excessive permissions
* Insecure storage settings
* Missing encryption
* Insecure identity configuration

---

# 37. Access Control Model

The environment follows role based access control.

The main identities are:

| Identity                | Purpose                       | Primary Access                                   |
| ----------------------- | ----------------------------- | ------------------------------------------------ |
| GitHub Actions Identity | CI/CD                         | Contributor, ACR Push, Key Vault Secrets Officer |
| VM Managed Identity     | Application runtime           | ACR Pull, Key Vault Secrets User                 |
| Azure Administrator     | Infrastructure administration | Controlled Azure administrative access           |

The permissions are assigned according to operational responsibilities.

---

# 38. Separation of Duties

The solution separates responsibilities between application deployment and infrastructure approval.

```text
Developer
    |
    v
Code Change
    |
    v
Automated Tests
    |
    v
Terraform Plan
    |
    v
Authorised Approval
    |
    v
Terraform Apply
    |
    v
Application Deployment
```

This reduces the risk of a single uncontrolled action modifying the complete environment.

---

# 39. Security and Governance Mapping

The security implementation supports the six assessment dimensions.

| Dimension          | Security Implementation                                              |
| ------------------ | -------------------------------------------------------------------- |
| Governance         | Terraform Plan, approval gates, Git history, protected environments  |
| Technology         | Azure, Docker, GitHub Actions, Terraform, ACR, Key Vault             |
| Security           | OIDC, Managed Identity, RBAC, NSG, Key Vault                         |
| Service Delivery   | Automated validation, health checks, controlled deployment           |
| People             | Separation of Developer, DevOps, Cloud and Security responsibilities |
| Functional Process | Controlled development, testing, approval and deployment process     |

---

# 40. Security Incident Response

If a security issue is suspected:

## Step 1

Stop further deployments if required.

## Step 2

Review the GitHub Actions workflow history.

## Step 3

Review recent Git commits.

## Step 4

Review Azure Activity Log.

## Step 5

Review identity and RBAC assignments.

## Step 6

Review Key Vault access.

## Step 7

Review ACR image history.

## Step 8

Identify affected resources.

## Step 9

Rotate compromised credentials or secrets where applicable.

## Step 10

Redeploy a known good application version.

---

# 41. Credential Rotation

If an application secret is compromised:

1. Identify the affected secret.
2. Rotate the secret in the appropriate secure store.
3. Update the application configuration.
4. Redeploy the application.
5. Verify application health.
6. Review access logs.
7. Confirm that the old credential is no longer valid.

Azure Key Vault should be used for application secrets rather than storing credentials in source code.

---

# 42. Compromised GitHub Credential Response

If a GitHub Actions credential is suspected to be compromised:

1. Review the affected GitHub Actions workflow.
2. Review Azure Activity Logs.
3. Review the federated identity configuration.
4. Review Azure RBAC assignments.
5. Disable or remove the affected federated credential if required.
6. Review recent infrastructure changes.
7. Recreate the trusted federation configuration if necessary.
8. Validate the CI/CD pipeline.

OIDC reduces the risk associated with long lived Azure client secrets because authentication is based on short lived tokens.

---

# 43. Compromised VM Response

If the VM is suspected to be compromised:

1. Restrict network access.
2. Stop application deployment.
3. Review VM activity.
4. Review Docker containers.
5. Review Docker images.
6. Review VM Managed Identity permissions.
7. Review Azure Activity Logs.
8. Rebuild the VM from Terraform if required.
9. Redeploy a known good Docker image.
10. Validate application health.

Infrastructure should be rebuilt from version controlled Terraform where practical rather than relying on manual recovery.

---

# 44. Security Validation Checklist

Before release:

```text
[ ] Application tests pass
[ ] Terraform format check passes
[ ] Terraform validation passes
[ ] Terraform plan reviewed
[ ] Approval obtained
[ ] Docker image built
[ ] Docker image identified by commit SHA
[ ] ACR push successful
[ ] VM pulls image using Managed Identity
[ ] ACR admin authentication remains disabled
[ ] Application health check passes
[ ] Application readiness check passes
[ ] Application Gateway backend is healthy
```

---

# 45. Security Best Practices

The following practices should be maintained:

* Never commit private keys.
* Never commit passwords.
* Never commit Azure client secrets.
* Never hard code application credentials.
* Use Managed Identity where possible.
* Use OIDC for GitHub to Azure authentication.
* Use Azure RBAC.
* Follow least privilege.
* Keep ACR administrator authentication disabled.
* Protect Terraform Apply.
* Protect Terraform Destroy.
* Keep Terraform state outside the Git repository.
* Review infrastructure changes before approval.
* Use immutable application image tags.
* Regularly update dependencies.
* Regularly scan container images.
* Regularly review Azure RBAC assignments.

---

# 46. Future Security Enhancements

The current implementation provides the core security controls required for the assessment.

Potential future improvements include:

* GitHub CodeQL
* Container image vulnerability scanning
* Terraform security scanning
* Python dependency vulnerability scanning
* Azure Defender for Cloud
* Azure Monitor
* Log Analytics
* Application Insights
* Web Application Firewall on Application Gateway
* Private Azure Container Registry networking
* Private endpoints
* Network Watcher
* Centralised security logging
* Automated secret rotation
* Automated vulnerability remediation
* Automated security gates in CI/CD

A more advanced security pipeline could become:

```text
Developer
    |
    v
GitHub
    |
    v
SAST
    |
    v
Dependency Scan
    |
    v
Unit Tests
    |
    v
Terraform Security Scan
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
Container Scan
    |
    v
ACR
    |
    v
Deployment
    |
    v
Health Validation
```

---

# 47. Security Summary

The 10Alytics deployment implements security across identity, infrastructure, network, application and CI/CD layers.

The key controls are:

```text
OIDC
  +
Managed Identity
  +
Azure RBAC
  +
Key Vault
  +
Network Security
  +
SSH Key Authentication
  +
Disabled Password Authentication
  +
Disabled ACR Admin Authentication
  +
Protected Terraform Apply
  +
Protected Terraform Destroy
  +
Remote Terraform State
  +
GitHub Secrets
  +
Commit Based Docker Tags
```

The resulting security model provides controlled access, reduced credential exposure, infrastructure governance and deployment traceability.

The architecture can subsequently be extended with automated vulnerability scanning, Web Application Firewall, centralised logging and additional security gates as the application moves towards a more production oriented environment.
