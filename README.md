# AWS DevOps / SRE Hands-On Project

This repository is a practical starter for three tasks:
1. GitHub Actions → tests → Docker → Amazon ECR → Kubernetes (EKS)
2. CloudFront in front of a private S3 bucket using Origin Access Control (OAC)
3. Launch Template + Auto Scaling Group + ALB + target tracking at 70% CPU

> This is a project scaffold, not a claim that resources have already been deployed. Run and verify it in your own AWS account. AWS resources may incur charges.

## Repository structure

- `app/`: Flask demo app and tests
- `Dockerfile`: container build
- `.github/workflows/deploy.yml`: CI/CD workflow using GitHub OIDC
- `k8s/deployment.yaml`: Kubernetes Deployment and Service
- `terraform/cloudfront/`: private S3 + CloudFront distribution
- `terraform/asg/`: ALB + launch template + ASG + CPU target tracking
- `docs/validation-checklist.md`: evidence checklist

## Before you start

Required locally: Git, Docker, AWS CLI v2, kubectl, Terraform, and an AWS account with permission to create the required resources.

Choose one AWS region and use it consistently. The examples default to `ap-south-1`.

### GitHub Actions OIDC

1. Create an IAM OIDC provider for `token.actions.githubusercontent.com` in AWS (if not already present).
2. Create an IAM role trusted only by your repository and `main` branch. Restrict `sub` to `repo:OWNER/REPO:ref:refs/heads/main`.
3. Grant that role only the ECR push permissions it needs and permission to call `eks:DescribeCluster`.
4. Grant the role's IAM principal permission to deploy to the target EKS cluster through EKS access entries / Kubernetes RBAC.
5. In GitHub repository Settings → Secrets and variables → Actions, add secret `AWS_ROLE_ARN`.
6. Set repository variables `AWS_REGION`, `ECR_REPOSITORY`, and `EKS_CLUSTER_NAME`.

Never commit AWS keys, kubeconfig files, Terraform state, or secrets.

## CI/CD setup

1. Create an ECR repository named `sre-cicd-demo`.
2. Create an EKS cluster and configure the deployment identity as described above.
3. Create the Kubernetes deployment once, updating the placeholder image in `k8s/deployment.yaml` to an image in your ECR repository:
   `kubectl apply -f k8s/deployment.yaml`
4. Push this repository to GitHub's `main` branch.
5. Check Actions tab. The pipeline tests the app, builds and pushes an image tagged with the commit SHA, then updates the Deployment.
6. Confirm with:
   `kubectl rollout status deployment/sre-demo`
   `kubectl get pods,svc`

The GitHub workflow pins actions to major version tags for readability in this learning project. For production, review and pin actions to full commit SHAs.

## CloudFront + private S3

Use Terraform in `terraform/cloudfront`. The bucket is private and CloudFront uses OAC to read objects. Upload `index.html` and any assets after `terraform apply`.

```bash
cd terraform/cloudfront
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

For a quick test, upload a file:
`aws s3 cp ../../site/index.html s3://$(terraform output -raw bucket_name)/index.html`

Test the CloudFront URL from `terraform output -raw cloudfront_domain_name`. Direct S3 object access should be denied. After updating content, invalidate the changed path:

`aws cloudfront create-invalidation --distribution-id "$(terraform output -raw distribution_id)" --paths "/index.html"`

## ALB + ASG

The Terraform example in `terraform/asg` uses the default VPC and its subnets to keep the lab concise. Review and adapt it before production use. It creates an internet-facing ALB, target group, Launch Template, Auto Scaling Group, and average CPU target tracking at 70%.

```bash
cd terraform/asg
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

The EC2 instances serve a simple Nginx page. Check the ALB URL from `terraform output -raw alb_dns_name`. In the EC2 console, inspect the ASG and target group health.

To test replacement in a lab, stop Nginx on one instance using Session Manager or another approved access method. Wait for ALB health checks to fail and confirm the ASG replaces the instance. Do not do this on production workloads.

## Cleanup

Run `terraform destroy` from each Terraform directory after you finish. Delete the EKS cluster and ECR images/repository separately if you created them separately. Confirm there are no leftover load balancers, NAT gateways, EC2 instances, CloudFront distributions, or S3 buckets.

## Submission evidence

Capture genuine screenshots of:
- GitHub Actions workflow passing
- ECR image tagged with the commit SHA
- Kubernetes rollout and running pods
- CloudFront website loading and direct S3 access denied
- Invalidation status
- ALB target group healthy instances
- ASG scaling policy with target CPU 70%
- ASG activity history showing an unhealthy instance replaced

Do not submit fabricated screenshots or claim unverified deployment results.
