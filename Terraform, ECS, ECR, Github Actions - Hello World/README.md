### Objective
Deploy a containerized app to ECS Fargate behind an Application Load Balancer, provisioned by Terraform,
deployed by a CI/CD pipeline.
Add an Application Auto Scaling target and a target-tracking policy on the
ECS service (your choice of metric — CPU, memory, or ALB request count per target).

### Prerequisites
1. Create GitHub secrets `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`. Required for the CI/CD workflow.
2. Create a Terraform backend S3 bucket (enable bucket versioning). Make sure its name is same as specified in `terraform/versions.tf`.

### Setup
Once the ECS service is deployed using Terraform, the app will be accessible via the ALB DNS endpoint
(`curl $(terraform output -raw app_url)`)

### Autoscaling validation approach
Use an open-source performance testing tool like **Locust** (highly native for a Python app) or **k6**.
1. Establish the Baseline: run a steady test of 50 concurrent users for 5 minutes. Verify that 1 task easily handles the traffic and memory hovers safely below 50%.
2. Simulate a Traffic Spike (Scale-Out Validation): Configure a steep step-load test.
   - Ramp up from 50 to 500 concurrent users over 60 seconds.
   - Maintain this load for 10 minutes.
   - Expected Result: Memory footprint will cross 358 MB. Within 45 seconds (`scale_out_cooldown`), CloudWatch will trigger an alarm, and the ECS `desired_count` will incrementally scale from 1 up towards 5.
3. Simulate Traffic Drop (Scale-In Validation): Abruptly drop the virtual users back down to 0.
   - Expected Result: The memory utilization will drop. After 180 seconds (`scale_in_cooldown`), Application Auto Scaling will systematically terminate idle tasks until the service safely settles back down to the `min_capacity` of 1.
4. Monitor the Deployment Caveats: During load testing, keep a close eye on `APP_WARMUP_SECONDS` environment variable (set to `25`). Ensure that the ALB Target Group health check timeout and intervals are tuned appropriately; otherwise, the task won't accept traffic quickly enough during a scale-out event, routing load to overwhelmed tasks.

### Fargate vs. EC2 vs. EKS
For a small team maintaining this workload long-term, the preferred approach is **ECS Fargate**. 
1. Operational Burden:
   - Kubernetes requires regular control plane upgrades, management of worker node groups, VPC CNI networking, and complex YAML configurations (Deployments, Services, Ingress Controllers, HPA). For a small team, EKS often turns into a full-time job managing infrastructure rather than shipping Python code.
   - ECS on EC2 requires managing, patching and scaling of EC2 instances. While less complex than EKS, it still requires ongoing attention to ensure optimal performance and security.
2. Cost:
   - EKS charges large sums of money just for the cluster control plane before you even launch a single container or server. EKS is financially inefficient for small workloads.
   - ECS on EC2 requires maintenance of the EC2 instances. One hour of an engineer's salary costs significantly more than the entire Fargate bill.

### Improvements
- Change the CI/CD workflow's AWS authentication method to OIDC
- Separate the Terraform code into reusable modules, rather than a single monolithic
- Move IaC CI/CD process into a separate pipeline, with changes validation and manual approvals as well
- Use a concrete container image tag rather than `latest`
