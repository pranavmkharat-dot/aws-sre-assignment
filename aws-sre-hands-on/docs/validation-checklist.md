# Submission Validation Checklist

Mark each item only after you personally verify it.

## CI/CD
- [ ] GitHub Actions test step passed.
- [ ] Docker image pushed to ECR with commit SHA tag.
- [ ] EKS Deployment updated to that image.
- [ ] `kubectl rollout status deployment/sre-demo` succeeded.
- [ ] Evidence screenshots captured.

## CloudFront + S3
- [ ] S3 Block Public Access enabled.
- [ ] CloudFront OAC configured and bucket policy scoped to distribution ARN.
- [ ] CloudFront URL serves `index.html`.
- [ ] Direct S3 object URL returns AccessDenied/403.
- [ ] Invalidation completed and updated content verified.

## ALB + ASG
- [ ] ALB spans at least two AZs.
- [ ] Target group reports healthy instances.
- [ ] ASG min/desired/max values recorded.
- [ ] Target tracking policy target is 70% average CPU.
- [ ] In a disposable lab, unhealthy target is replaced and returns healthy.
- [ ] ASG activity history screenshot captured.

## Cleanup
- [ ] Destroy unneeded Terraform resources.
- [ ] Remove test ECR images/repository and EKS resources if created separately.
- [ ] Confirm no billable resources remain.
