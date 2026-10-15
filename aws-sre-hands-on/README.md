# AWS DevOps / SRE Hands-On Project

This repository demonstrates practical AWS infrastructure, CI validation, container packaging, static-site delivery, and instance self-healing. It covers three assignment areas:

1. GitHub Actions CI for Python tests and Docker image build, with Amazon ECR publishing and Kubernetes deployment as the remaining end-to-end CI/CD work.
2. A private Amazon S3 origin served through CloudFront using Origin Access Control (OAC).
3. Terraform-managed Launch Template, Auto Scaling Group (ASG), Application Load Balancer (ALB), target group, health checks, and CPU target tracking at 70%.

> **Current status:** The project is partially complete. The infrastructure components described below have been deployed and validated in the assignment AWS account. Automated GitHub Actions-to-ECR publishing and Kubernetes deployment are not yet complete. AWS resources can incur charges.

## Repository layout

From the GitHub repository root:

```text
.github/workflows/
  deploy.yml                 # Python tests and Docker build
  terraform-validate.yml     # Terraform validation workflow
aws-sre-hands-on/
  app/                       # Flask demo app and tests
  Dockerfile                 # Container build definition
  k8s/deployment.yaml        # Kubernetes Deployment and Service manifest
  site/                      # Static website content
  terraform/cloudfront/     # Private S3 + CloudFront configuration
  terraform/asg/             # ALB + Launch Template + ASG configuration
  docs/validation-checklist.md
  requirements.txt
```

## Implementation status

### Implemented and validated

- **GitHub Actions:** The workflow has passed the Python test and Docker build jobs. It is currently a CI/build workflow; it does not yet push to ECR or deploy to Kubernetes.
- **Amazon ECR:** Repository `aws-sre-assignment` exists in `ap-southeast-2` (Sydney). Image tag `build-1` was pushed manually and verified. Image-tag immutability and scan-on-push are enabled.
- **S3 + CloudFront:** Static content is served through CloudFront. The CloudFront URL returned HTTP 200 during validation, while direct access to an S3 object returned HTTP 403. The bucket policy limits read access to the CloudFront distribution through OAC.
- **ALB + ASG:** Terraform provisions an internet-facing ALB, target group, Launch Template, ASG, and CPU target-tracking policy at 70% average CPU utilization. An unhealthy-instance test confirmed that ASG launched a replacement instance that reached `InService` and became healthy in the target group.
- **Terraform:** Infrastructure configurations are maintained as code under `terraform/cloudfront/` and `terraform/asg/`.

### Remaining work / known limitations

1. Complete an approved GitHub Actions-to-AWS authentication method and automate the ECR image push.
2. Create or obtain access to an approved EKS/Kubernetes environment if Kubernetes deployment is required by the evaluator, then deploy and validate the workload.
3. Run end-to-end validation after the CI/CD integration is available and capture the remaining evidence.
4. Correct the demo response's instance-ID display: the current user-data script needs to retrieve instance metadata in a way compatible with the environment's IMDSv2 requirement.

The GitHub Actions OIDC setup is currently blocked because an AWS Organizations Service Control Policy explicitly denies the IAM OIDC provider operation. This cannot be resolved just by attaching `AdministratorAccess` in the member account. The next step is to obtain guidance/approval from the AWS Organizations management-account administrator and/or AWS Support, or use another approved authentication path. Do not attempt to bypass the organization policy.

No EKS cluster currently exists in `ap-southeast-2` for this assignment, so Kubernetes deployment should not be represented as completed. Creating EKS may incur additional charges and should be approved before provisioning.

## Prerequisites

For local testing and infrastructure changes, install Git, Python 3.12, Docker, AWS CLI v2, Terraform, and (when deploying Kubernetes) `kubectl`. Use an AWS identity that has been explicitly authorized to manage the target resources.

The deployed assignment environment uses **`ap-southeast-2` (Asia Pacific — Sydney)**. Keep the region consistent when inspecting these resources. If reproducing the project in another account or region, review the variables and Terraform plan first; do not assume existing resource names or identifiers will be available.

Never commit AWS keys, access tokens, kubeconfig files, Terraform state, state backups, or other secrets.

## Run the tests and build the container

Run from the repository root:

```bash
python -m pip install --upgrade pip
python -m pip install -r aws-sre-hands-on/requirements.txt
python -m pip install pytest
python -m pytest aws-sre-hands-on/app/

docker build -t aws-sre-assignment:local aws-sre-hands-on
```

The GitHub Actions workflow currently automates the test and image-build stages. The manual ECR image push described below is separate from that workflow.

## Amazon ECR reference

- **Region:** `ap-southeast-2`
- **Repository:** `aws-sre-assignment`
- **Repository URI:** `134129016924.dkr.ecr.ap-southeast-2.amazonaws.com/aws-sre-assignment`
- **Manually pushed tag:** `build-1`
- **Verified image digest:** `sha256:3084fbb4cb85bacb11ff76d48c62414a885dc35732cc6387430f9f594d133631`

The repository uses immutable image tags and scan-on-push. The current `build-1` image was pushed manually; it was not published by the GitHub Actions workflow.

## CloudFront + private S3

The Terraform configuration is in `aws-sre-hands-on/terraform/cloudfront/`. The current deployed references are:

- **CloudFront URL:** https://d6wyav0pk3m6.cloudfront.net
- **Distribution ID:** `EYCCN3Y8EQF34`
- **S3 bucket:** `aws-sre-assignment-134129016924-ap-southeast-2`

Validation performed: the CloudFront site returned HTTP 200, while direct S3 object access returned HTTP 403. The S3 bucket policy authorizes CloudFront access through OAC for the intended distribution.

To review or apply the Terraform configuration in a dedicated environment, run from the repository root:

```bash
cd aws-sre-hands-on/terraform/cloudfront
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the complete plan before applying changes. Terraform state is environment-specific and should not be committed. After website content changes, invalidate the relevant CloudFront path using the distribution ID for the environment you are updating:

```bash
aws cloudfront create-invalidation \
  --distribution-id "<DISTRIBUTION_ID>" \
  --paths "/index.html"
```

## ALB + Auto Scaling Group

The Terraform configuration is in `aws-sre-hands-on/terraform/asg/`. The current deployed references are:

- **ALB DNS:** `sre-web-alb-529081989.ap-southeast-2.elb.amazonaws.com`
- **Auto Scaling Group:** `sre-web-asg`
- **Launch Template ID:** `lt-06239d8069c1e32b6`
- **Capacity:** minimum 1, desired 1, maximum 2
- **Instance type:** `t3.micro`
- **CPU target-tracking target:** 70% average CPU utilization

A failure test was performed by marking an instance unhealthy. The ASG launched a replacement and the replacement became healthy in the target group. Do not repeat failure tests on production workloads or shared environments without approval.

To review the configuration in a dedicated environment:

```bash
cd aws-sre-hands-on/terraform/asg
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the planned changes before applying them. The example uses a default VPC and its subnets for lab simplicity; adapt and security-review it before any production use.

## Kubernetes deployment status

The repository includes `aws-sre-hands-on/k8s/deployment.yaml`, but the Kubernetes deployment has **not** been validated in a live EKS cluster for this assignment. Before deployment:

1. Obtain approval for an EKS cluster or the target Kubernetes environment and understand the expected costs.
2. Configure an approved deployment identity and grant the necessary EKS access / Kubernetes RBAC permissions.
3. Update the manifest to reference the correct ECR image URI and tag.
4. Apply the manifest and verify the rollout and running pods.

Only mark this section complete after the workload is actually deployed and validated.

## Cleanup and cost awareness

The assignment environment contains deployed AWS resources. **Do not run `terraform destroy` against the current/shared environment unless you are authorized to remove those resources.** Destroying CloudFront or related infrastructure can take the live demo offline.

For a separate lab environment that you own, inspect Terraform state and the destroy plan in each Terraform directory before confirming cleanup. Delete separately created resources (such as ECR repositories/images or an EKS cluster) only after checking their dependencies. Afterwards, verify that no billable resources remain, including load balancers, EC2 instances, NAT gateways, CloudFront distributions, and S3 buckets.

## Submission evidence checklist

Capture genuine screenshots or command output for the items that are actually complete:

- [x] GitHub Actions test and Docker build jobs passed
- [x] ECR repository and manually pushed `build-1` image verified
- [x] CloudFront website returned HTTP 200
- [x] Direct S3 object access returned HTTP 403
- [x] CloudFront invalidation created
- [x] ALB target group returned to healthy status after ASG instance replacement
- [x] ASG CPU target-tracking policy configured at 70%
- [ ] GitHub Actions automatically authenticates to AWS and pushes an image to ECR
- [ ] Kubernetes deployment / rollout and running pods validated in an approved cluster
- [ ] Final end-to-end CI/CD validation completed

Do not submit fabricated screenshots or claim unverified deployment results. The current completion estimate is approximately 85%; this is a project estimate, not an AWS-generated status.

## Project links

- **GitHub repository:** https://github.com/pranavmkharat-dot/aws-sre-assignment
- **Live CloudFront demo:** https://d6wyav0pk3m6.cloudfront.net
