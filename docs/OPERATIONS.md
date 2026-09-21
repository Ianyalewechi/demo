# 10Alytics DevOps Assessment

# Operations Documentation

## 1. Overview

This document describes the operational procedures for the 10Alytics application after deployment.

It covers:

* Application monitoring
* Health checks
* Readiness checks
* Docker container management
* Azure VM operations
* Application Gateway monitoring
* Azure Container Registry operations
* CI/CD monitoring
* Deployment verification
* Troubleshooting
* Application rollback
* Infrastructure recovery
* Operational responsibilities

The operational model is designed to provide reliable application delivery, fast issue identification and controlled recovery.

---

# 2. Production Architecture

The deployed application follows this operational path:

```text
Internet
   |
   v
Azure Application Gateway
   |
   v
Azure VM
   |
   v
Docker Container
   |
   v
Flask Application
```

The application is publicly accessed through Azure Application Gateway.

The current Application Gateway endpoint is:

```text
http://20.4.241.133/
```

The Application Gateway forwards traffic to the VM backend:

```text
10.10.1.4:80
```

The Docker container listens internally on:

```text
5000
```

The VM maps:

```text
80:5000
```

---

# 3. Operational Health Model

The application exposes two operational endpoints.

## Health Endpoint

```text
/health
```

Purpose:

Determines whether the application process is running.

Example:

```text
http://20.4.241.133/health
```

Expected result:

```json
{
  "status": "healthy"
}
```

---

# 4. Readiness Endpoint

The readiness endpoint is:

```text
/health/ready
```

Purpose:

Determines whether the application is ready to receive traffic.

Example:

```text
http://20.4.241.133/health/ready
```

Expected result:

```json
{
  "status": "ready"
}
```

Both endpoints are checked during the CI/CD deployment process.

---

# 5. Application Monitoring

Application monitoring currently uses the following mechanisms:

* Application health endpoint
* Application readiness endpoint
* Docker container status
* Application Gateway backend health
* GitHub Actions deployment status
* Azure VM Run Command
* Azure resource monitoring

These provide several layers of operational visibility.

```text
Application
     |
     +--> /health
     |
     +--> /health/ready
     |
     +--> Docker Status
     |
     +--> VM Status
     |
     +--> Application Gateway Health
     |
     +--> CI/CD Status
```

---

# 6. Application Gateway Monitoring

Azure Application Gateway is the primary public entry point.

The Application Gateway backend pool contains:

```text
10.10.1.4
```

The backend uses:

```text
Protocol: HTTP
Port: 80
```

The backend health probe should report:

```text
Healthy
```

with an HTTP status:

```text
200
```

If the backend becomes unhealthy, investigate:

1. VM availability
2. Docker container status
3. Port 80 binding
4. Flask application status
5. Application health endpoint
6. Network Security Group rules
7. Application Gateway backend configuration

---

# 7. Docker Container Monitoring

The application container is:

```text
10alytics-app
```

Check running containers:

```bash
docker ps
```

Example:

```text
CONTAINER ID
IMAGE
STATUS
PORTS
NAMES
```

The expected container name is:

```text
10alytics-app
```

---

# 8. Check All Docker Containers

Run:

```bash
docker ps -a
```

This shows both running and stopped containers.

This is useful when the application container has stopped unexpectedly.

Look for:

```text
10alytics-app
```

---

# 9. Check Container Logs

View application logs:

```bash
docker logs 10alytics-app
```

Follow logs in real time:

```bash
docker logs -f 10alytics-app
```

Limit the output:

```bash
docker logs --tail 100 10alytics-app
```

These commands are useful for investigating application startup failures and runtime errors.

---

# 10. Check Container Resource Usage

Run:

```bash
docker stats 10alytics-app
```

This displays:

* CPU usage
* Memory usage
* Network usage
* Block I/O
* Process information

This can help identify resource exhaustion.

---

# 11. Check Application Health on the VM

Use:

```bash
curl http://localhost/health
```

Expected response:

```json
{
  "status": "healthy"
}
```

Then:

```bash
curl http://localhost/health/ready
```

Expected response:

```json
{
  "status": "ready"
}
```

---

# 12. Check Application Health from Azure VM Run Command

The VM can be managed without opening SSH access to the internet.

Azure Run Command can execute commands remotely.

Example:

```bash
az vm run-command invoke \
  --resource-group "rg-10alytics-devops" \
  --name "vm-10alytics" \
  --command-id RunShellScript \
  --scripts "curl --fail http://localhost/health"
```

Readiness:

```bash
az vm run-command invoke \
  --resource-group "rg-10alytics-devops" \
  --name "vm-10alytics" \
  --command-id RunShellScript \
  --scripts "curl --fail http://localhost/health/ready"
```

---

# 13. Check VM Status

Check the Azure VM:

```bash
az vm get-instance-view \
  --resource-group "rg-10alytics-devops" \
  --name "vm-10alytics" \
  --query "instanceView.statuses"
```

The VM should report a running state.

---

# 14. Check VM Networking

Retrieve the VM private IP:

```bash
az vm show \
  --resource-group "rg-10alytics-devops" \
  --name "vm-10alytics" \
  --show-details \
  --query privateIps \
  --output tsv
```

Expected private IP:

```text
10.10.1.4
```

---

# 15. Check Application Port

The application should be available on port 80 on the VM.

Run:

```bash
curl -I http://localhost/
```

Expected result:

```text
HTTP/1.1 200 OK
```

If this fails, check the Docker container.

---

# 16. Check Docker Port Mapping

Run:

```bash
docker port 10alytics-app
```

Expected mapping:

```text
5000/tcp -> 0.0.0.0:80
```

The mapping means:

```text
VM Port 80
     |
     v
Container Port 5000
```

---

# 17. Check Application Gateway Backend Health

Use Azure CLI:

```bash
az network application-gateway show-backend-health \
  --resource-group "rg-10alytics-devops" \
  --name "agw-10alytics"
```

The backend should report:

```text
Healthy
```

The expected backend is:

```text
10.10.1.4
```

---

# 18. Check Public Application Access

Open:

```text
http://20.4.241.133/
```

The application should load successfully.

Health:

```text
http://20.4.241.133/health
```

Readiness:

```text
http://20.4.241.133/health/ready
```

If the public application is unavailable but local VM health checks pass, investigate Application Gateway.

---

# 19. CI/CD Monitoring

GitHub Actions provides visibility into every deployment.

The primary workflow is:

```text
.github/workflows/ci-cd.yml
```

The pipeline contains:

```text
Test
   |
Terraform Plan
   |
Terraform Apply
   |
Build
   |
Deploy
   |
Health Check
```

Each stage must complete successfully before the next dependent stage runs.

---

# 20. CI/CD Failure Handling

If the test stage fails:

```text
Test
  |
  X
Pipeline stops
```

Infrastructure changes are not applied.

If Terraform Plan fails:

```text
Terraform Plan
      |
      X
Pipeline stops
```

If Terraform Apply is awaiting approval:

```text
Terraform Apply
      |
      v
Approval Required
```

If the approval is not granted, the infrastructure deployment does not continue.

If Docker Build fails:

```text
Docker Build
      |
      X
Deployment stops
```

If the deployment health check fails:

```text
Application Deployment
      |
      v
Health Check
      |
      X
Pipeline reports failure
```

---

# 21. Deployment Verification Procedure

After every deployment, perform the following checks.

## Step 1: Check GitHub Actions

Confirm that:

```text
Test
Terraform Plan
Terraform Apply
Build
Deploy
Health Check
```

have completed successfully.

## Step 2: Check Docker

```bash
docker ps
```

Confirm:

```text
10alytics-app
```

is running.

## Step 3: Check Health

```bash
curl http://localhost/health
```

## Step 4: Check Readiness

```bash
curl http://localhost/health/ready
```

## Step 5: Check Application Gateway

Confirm backend:

```text
10.10.1.4
```

is:

```text
Healthy
```

## Step 6: Check Public Application

Open:

```text
http://20.4.241.133/
```

---

# 22. Standard Troubleshooting Flow

When the application is unavailable, troubleshoot from the inside out.

```text
Public Application
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
Flask Application
```

This avoids making assumptions about the failure point.

---

# 23. Troubleshooting: Application Not Loading

If the public application is unavailable:

### Step 1

Check Application Gateway backend health.

```bash
az network application-gateway show-backend-health \
  --resource-group "rg-10alytics-devops" \
  --name "agw-10alytics"
```

### Step 2

If the backend is unhealthy, check the VM.

### Step 3

Check Docker:

```bash
docker ps
```

### Step 4

Check logs:

```bash
docker logs --tail 100 10alytics-app
```

### Step 5

Check local application:

```bash
curl http://localhost/health
```

### Step 6

Check readiness:

```bash
curl http://localhost/health/ready
```

---

# 24. Troubleshooting: Container Not Running

Check:

```bash
docker ps -a
```

If the container is stopped, inspect logs:

```bash
docker logs 10alytics-app
```

Try restarting:

```bash
docker restart 10alytics-app
```

Then check:

```bash
docker ps
```

And:

```bash
curl http://localhost/health
```

---

# 25. Troubleshooting: Container Keeps Restarting

Check:

```bash
docker ps -a
```

Then:

```bash
docker logs --tail 200 10alytics-app
```

Inspect the container:

```bash
docker inspect 10alytics-app
```

Check whether the Docker image is valid:

```bash
docker images
```

Check available disk space:

```bash
df -h
```

Check memory:

```bash
free -h
```

---

# 26. Troubleshooting: Docker Image Cannot Be Pulled

If the VM cannot pull the image from Azure Container Registry, verify the VM identity.

The VM identity should have:

```text
AcrPull
```

on:

```text
acr10alyticsikedi
```

Test Azure authentication from the VM:

```bash
az login --identity --allow-no-subscriptions
```

Then:

```bash
az acr login --name acr10alyticsikedi
```

If authentication fails, check:

* VM Managed Identity
* AcrPull role assignment
* Azure Container Registry availability
* Azure CLI installation
* Network connectivity

---

# 27. Troubleshooting: ACR Image Does Not Exist

List repositories:

```bash
az acr repository list \
  --name acr10alyticsikedi \
  --output table
```

List image tags:

```bash
az acr repository show-tags \
  --name acr10alyticsikedi \
  --repository 10alytics-app \
  --output table
```

Confirm that the required Git commit SHA exists.

---

# 28. Troubleshooting: Health Endpoint Fails

Run:

```bash
curl -v http://localhost/health
```

If it fails:

1. Check the Docker container.
2. Check container logs.
3. Check port mapping.
4. Check Flask application startup.
5. Check VM resources.

Check the container:

```bash
docker ps
```

Check logs:

```bash
docker logs 10alytics-app
```

Check port mapping:

```bash
docker port 10alytics-app
```

---

# 29. Troubleshooting: Readiness Endpoint Fails

Run:

```bash
curl -v http://localhost/health/ready
```

If readiness fails while health succeeds, the application process may be running but the application may not be ready to serve traffic.

Investigate:

* Application startup
* Configuration
* Required dependencies
* Application logs
* Runtime errors

---

# 30. Troubleshooting: Application Gateway Unhealthy

If the VM application is healthy locally but Application Gateway reports unhealthy:

Check:

```text
VM private IP
Backend port
Backend protocol
Health probe
Network Security Group
Application Gateway configuration
```

The expected configuration is:

```text
Backend:
10.10.1.4

Protocol:
HTTP

Port:
80
```

Verify locally:

```bash
curl http://localhost/
```

If this succeeds but Application Gateway remains unhealthy, investigate network connectivity and Application Gateway configuration.

---

# 31. Troubleshooting: Terraform Plan Failure

Run locally:

```powershell
terraform fmt -check
```

Then:

```powershell
terraform validate
```

Then:

```powershell
terraform plan
```

Check:

* Azure authentication
* Subscription
* Terraform variables
* Resource names
* Azure permissions
* Remote state backend
* Existing Azure resources

---

# 32. Troubleshooting: Terraform State Lock

If Terraform reports that the state is locked, do not immediately force unlock it.

First determine whether another Terraform operation is currently running.

Check:

* GitHub Actions
* Other engineers
* Local Terraform processes

Only remove a stale state lock after confirming that no Terraform operation is active.

---

# 33. Troubleshooting: GitHub Actions Azure Authentication

The GitHub Actions workflow uses OpenID Connect.

The workflow requires:

```text
id-token: write
contents: read
```

The Azure login configuration uses:

```yaml
- name: Login to Azure using OIDC
  uses: azure/login@v3
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

If authentication fails, verify:

* `AZURE_CLIENT_ID`
* `AZURE_TENANT_ID`
* `AZURE_SUBSCRIPTION_ID`
* Federated identity credential
* GitHub repository name
* GitHub branch
* GitHub Environment name

---

# 34. Application Rollback

The application images are tagged using Git commit SHA values.

Example:

```text
acr10alyticsikedi.azurecr.io/10alytics-app:abc123
acr10alyticsikedi.azurecr.io/10alytics-app:def456
acr10alyticsikedi.azurecr.io/10alytics-app:ghi789
```

This allows a previously deployed version to be identified and redeployed.

The current implementation provides a manual rollback mechanism.

It does not automatically roll back to the previous application version.

---

# 35. Manual Application Rollback

First identify the previously known good image.

List image tags:

```bash
az acr repository show-tags \
  --name acr10alyticsikedi \
  --repository 10alytics-app \
  --output table
```

Authenticate to ACR:

```bash
az acr login --name acr10alyticsikedi
```

Pull the required image:

```bash
docker pull acr10alyticsikedi.azurecr.io/10alytics-app:<KNOWN_GOOD_SHA>
```

Stop the current container:

```bash
docker rm -f 10alytics-app
```

Start the known good version:

```bash
docker run -d \
  --name 10alytics-app \
  --restart unless-stopped \
  -p 80:5000 \
  acr10alyticsikedi.azurecr.io/10alytics-app:<KNOWN_GOOD_SHA>
```

Verify:

```bash
curl --fail http://localhost/health
```

Then:

```bash
curl --fail http://localhost/health/ready
```

Finally verify Application Gateway backend health.

---

# 36. Rollback Through Azure VM Run Command

The rollback can also be performed without direct SSH access.

Example:

```bash
az vm run-command invoke \
  --resource-group "rg-10alytics-devops" \
  --name "vm-10alytics" \
  --command-id RunShellScript \
  --scripts "
    az login --identity --allow-no-subscriptions
    az acr login --name acr10alyticsikedi
    docker pull acr10alyticsikedi.azurecr.io/10alytics-app:<KNOWN_GOOD_SHA>
    docker rm -f 10alytics-app || true
    docker run -d \
      --name 10alytics-app \
      --restart unless-stopped \
      -p 80:5000 \
      acr10alyticsikedi.azurecr.io/10alytics-app:<KNOWN_GOOD_SHA>
    sleep 10
    curl --fail http://localhost/health
    curl --fail http://localhost/health/ready
  "
```

Replace:

```text
<KNOWN_GOOD_SHA>
```

with the required Git commit SHA.

---

# 37. Infrastructure Recovery

Infrastructure is managed through Terraform.

If infrastructure requires recovery or modification:

```text
Terraform Configuration
        |
        v
Terraform Plan
        |
        v
Review
        |
        v
Approval
        |
        v
Terraform Apply
```

Infrastructure changes should not be made manually where the resource is managed by Terraform unless there is an operational reason to do so.

After manual Azure changes, Terraform state and configuration should be reviewed to prevent configuration drift.

---

# 38. Infrastructure Destruction

Infrastructure destruction is separated from normal deployment.

The workflow is:

```text
Manual Workflow Trigger
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

The workflow is:

```text
.github/workflows/destroy.yml
```

The protected environment is:

```text
terraform-destroy
```

This prevents accidental destruction through a normal application deployment.

---

# 39. Operational Maintenance

Routine operational activities should include:

## Application

* Review application health
* Review application logs
* Review failed deployments
* Review container status

## Docker

* Remove obsolete local images where appropriate
* Monitor disk usage
* Monitor container resource consumption

## Azure

* Monitor VM availability
* Monitor Application Gateway health
* Monitor ACR
* Review Azure activity logs
* Review resource utilisation

## CI/CD

* Review failed GitHub Actions runs
* Review Terraform changes
* Review deployment history
* Review approval history

---

# 40. Deployment Change Process

Application changes should follow this process:

```text
Change Required
      |
      v
Developer Updates Code
      |
      v
Local Testing
      |
      v
Git Commit
      |
      v
Git Push
      |
      v
GitHub Actions
      |
      v
Automated Tests
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
ACR Push
      |
      v
Application Deployment
      |
      v
Health Validation
      |
      v
Release Complete
```

---

# 41. Operational Responsibilities

The following responsibilities can be assigned across the delivery team.

| Role                    | Responsibility                           |
| ----------------------- | ---------------------------------------- |
| Developer               | Application code and unit tests          |
| QA                      | Test validation and release verification |
| DevOps Engineer         | CI/CD and deployment automation          |
| Cloud Engineer          | Azure infrastructure                     |
| Security Engineer       | Identity, RBAC and security controls     |
| Infrastructure Engineer | VM, network and platform operations      |
| Operations              | Monitoring and incident response         |
| Application Owner       | Business acceptance                      |

---

# 42. Incident Response Procedure

When an application incident occurs:

## Step 1

Confirm the issue.

Check:

```text
Application URL
Health endpoint
Readiness endpoint
```

## Step 2

Check Application Gateway.

```text
Backend health
```

## Step 3

Check VM.

```text
VM status
```

## Step 4

Check Docker.

```bash
docker ps
```

## Step 5

Check logs.

```bash
docker logs --tail 200 10alytics-app
```

## Step 6

Determine the cause.

Possible causes include:

* Application failure
* Container failure
* Image failure
* VM failure
* Network failure
* Application Gateway failure
* Azure service failure

## Step 7

Recover.

Depending on the issue:

* Restart container
* Redeploy application
* Roll back application image
* Correct infrastructure configuration
* Reapply Terraform
* Escalate Azure infrastructure issue

## Step 8

Validate recovery.

Run:

```bash
curl --fail http://localhost/health
```

and:

```bash
curl --fail http://localhost/health/ready
```

Then verify Application Gateway.

---

# 43. Operational Logging

Application logs are available through Docker.

Use:

```bash
docker logs 10alytics-app
```

For continuous monitoring:

```bash
docker logs -f 10alytics-app
```

For recent logs:

```bash
docker logs --tail 100 10alytics-app
```

The current implementation uses container logs as the primary application log source.

A centralised logging platform such as Azure Monitor, Log Analytics or another enterprise observability platform can be added as a future enhancement.

---

# 44. Monitoring Enhancements

Future operational improvements could include:

* Azure Monitor
* Log Analytics Workspace
* Application Insights
* Centralised application logs
* Container metrics
* CPU and memory alerts
* Application Gateway alerts
* ACR monitoring
* Automated incident notifications
* Synthetic availability checks
* Automated application rollback
* Blue green deployment
* Canary deployment

These are not required for the current assessment implementation but provide a path towards a more advanced production operating model.

---

# 45. Current Rollback Capability

The current implementation supports:

```text
Manual application rollback
```

through immutable Git commit based Docker image tags.

It does not currently provide:

```text
Automatic application rollback
```

The deployment pipeline validates the new version after deployment, but a failed health check currently causes the pipeline to report failure rather than automatically deploying the previous version.

An automated rollback workflow can be implemented as a future enhancement.

---

# 46. Operational Checklist

Before deployment:

```text
[ ] Code reviewed
[ ] Tests passing
[ ] Terraform formatted
[ ] Terraform validated
[ ] Terraform plan reviewed
[ ] Approval granted
```

During deployment:

```text
[ ] Terraform Apply successful
[ ] Docker image built
[ ] Docker image pushed to ACR
[ ] VM deployment successful
[ ] Container running
```

After deployment:

```text
[ ] /health successful
[ ] /health/ready successful
[ ] Application Gateway backend healthy
[ ] Public application accessible
[ ] GitHub Actions completed successfully
```

---

# 47. Operational Summary

The 10Alytics solution provides a controlled operational model based on:

* Automated testing
* Infrastructure as Code
* Protected infrastructure changes
* Containerised application deployment
* Azure Container Registry
* Managed Identity
* Application health checks
* Readiness checks
* Application Gateway monitoring
* Docker operational checks
* GitHub Actions deployment history
* Commit based application versioning
* Manual application rollback
* Protected infrastructure destruction

The operational process is designed to make failures identifiable, deployments repeatable and recovery controlled.

```text
Monitor
   |
   v
Detect
   |
   v
Diagnose
   |
   v
Recover
   |
   v
Validate
   |
   v
Document
```
