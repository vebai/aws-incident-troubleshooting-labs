# AWS Incident Troubleshooting Labs

**Official optional companion laboratory for *AWS Incident Troubleshooting: 10 Evidence-Based Investigations* by Victor Ebai.**

**Book teaches. Repository provisions. You investigate.**

The book includes the investigations and their evidence, so you can learn from it without an AWS account. If you want to build hands-on experience, this repository provides the AWS resources and controlled failures you can investigate alongside the book. You can also explore the exercises independently; the complete diagnostic reasoning is taught in the book.

These labs use a **practice AWS account**, not production infrastructure. They can incur charges while running. Start with [prerequisites](PREREQUISITES.md) and [costs](COSTS.md).

## Start here

Work through the steps in this order:

1. **Download the files.** Clone the repository onto your computer.
2. **Prepare AWS.** Check your credentials, Region, required tools and likely costs.
3. **Choose an incident.** Some exercises need the shared Shop application; others run separately.
4. **Build and check.** Confirm the required environment works before introducing a fault.
5. **Create the failure.** Use the incident's documented control, then return to the book to investigate.
6. **Reset or clean up.** Restore the exercise, or remove AWS resources when finished.

**Before deploying Shop:** [replace the example HTTP source CIDR with your current public IPv4 address](#important-replace-the-example-ip-address-before-deployment). The sample IP cannot grant access to your computer.

Each experiment follows **Build → Verify → Inject → Investigate → Repair → Verify → Reset**. The scripts create faults and provide initial controls; **they do not provide a diagnosis or a substitute for the book**.

## Which environment do I need?

| Incident | Subject | Environment to create |
|---|---|---|
| [01](labs/incident-01/README.md) | Missing stack | Standalone CloudFormation stack; **no shared Shop needed** |
| [02](labs/incident-02/README.md) | Access denied | Shared Shop environment |
| [03](labs/incident-03/README.md) | Service unavailable | Shared Shop environment |
| [04](labs/incident-04/README.md) | Network path | Shared Shop environment |
| [05](labs/incident-05/README.md) | Load balancer checks | Shared Shop environment |
| [06](labs/incident-06/README.md) | S3 object | Shared Shop environment |
| [07](labs/incident-07/README.md) | Server startup | Shared Shop networking and S3, **plus a separate Terraform test** |
| [08](labs/incident-08/README.md) | Monitoring | Shared Shop environment; temporarily scale to **two targets** and restore one afterwards |
| [09](labs/incident-09/README.md) | Stack rollback | Shared Shop VPC, **plus a separate CloudFormation stack** |
| [10](labs/incident-10/README.md) | Multiple failures | Shared Shop environment; staged **alternative** three-fault exercise (not the book's exact faults) |

Incident 07's separate server is not connected to the Shop load balancer. Incident 09 has its own stack but needs the shared VPC. Read the corresponding incident guide before starting.

## 1. Download the files

Install [Git](https://git-scm.com/downloads) and open Terminal (macOS/Linux), or an appropriate shell on Windows:

```bash
git clone https://github.com/vebai/aws-incident-troubleshooting-labs.git
cd aws-incident-troubleshooting-labs
```

Run the commands below **from this repository directory on your computer**, except when the book specifically tells you to connect to an EC2 instance using Session Manager.

## 2. Prepare your AWS sandbox

Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [Terraform](https://developer.hashicorp.com/terraform/install) and the [AWS Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html). For permissions and account setup, see [PREREQUISITES.md](PREREQUISITES.md).

If you use AWS CLI access keys for a dedicated sandbox, configure a local profile:

```bash
aws configure --profile aws-labs
export AWS_PROFILE=aws-labs
export AWS_DEFAULT_REGION=eu-west-2
```

If your organisation uses AWS IAM Identity Center, follow its SSO setup instructions instead of creating long-lived keys. Then check the current shell:

```bash
aws --version
terraform version
aws sts get-caller-identity
aws configure list
scripts/preflight.sh
```

The incident scripts compare your active AWS account with the account recorded when Terraform created the lab. If the accounts differ, they refuse to operate. Use the original sandbox credentials or a correctly configured SSO profile; do not bypass the guard.

Confirm the **expected AWS account and Region** before creating resources. The project examples use `eu-west-2` (London). This matters because the labs change AWS resources deliberately. Keep credentials and local Terraform state private.

## Local source checks (no AWS changes)

From the repository root, run `bash scripts/validate-all.sh` to check Bash and Python syntax, expected lab guides and Terraform formatting. Terraform validation runs only for modules you have initialised; initialise each module with `terraform -chdir=<module> init -backend=false` when appropriate. These checks do not prove deployment, fault injection or cleanup. Keep live AWS testing separate.

## 3. Build the shared Shop environment

Skip this section if you are doing only **Incident 01**.

The shared Shop environment contains a small Python application on EC2, an Application Load Balancer, networking, an S3 catalogue and a CloudWatch alarm. Terraform creates these resources. The dedicated CloudFormation stacks are managed separately.

Make a private settings file:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars
```

### Important: Replace the example IP address before deployment

The `allowed_http_cidrs` setting controls which public IPv4 addresses can reach the Shop Application Load Balancer on HTTP port 80. **The sample value `203.0.113.10/32` is a documentation placeholder, not your computer’s address.** If you leave it unchanged, the ALB target may be healthy while requests from your computer time out.

On **your own computer** (not inside the EC2 Session Manager shell), find your current public IPv4 address:

```bash
curl -4 https://checkip.amazonaws.com
```

Then open `terraform/terraform.tfvars` and replace the example CIDR with the IPv4 address returned by that command, followed by `/32`. For example, if the command returned `198.51.100.25`, you would enter:

```hcl
allowed_http_cidrs = ["198.51.100.25/32"]
```

**Both example IPs above are documentation addresses. Use the actual address from your own command.** The `/32` suffix permits that single IPv4 address. Keep access limited to your intended source rather than opening the application to the whole internet.

Your public IP may change when you change networks or use a VPN. If the ALB target remains healthy but requests from your computer time out, check your current IP again and update `terraform/terraform.tfvars`. Review and apply a new Terraform plan before repeating the health checks.


Prepare and check the deployment:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out=shop.tfplan
```

Review the planned AWS resources, IAM changes and possible charges. When the plan describes only the environment you intend to build:

```bash
terraform -chdir=terraform apply shop.tfplan
scripts/show-resources.sh
scripts/validate-baseline.sh
```

### Verify the healthy baseline before injecting a failure

Run `scripts/validate-baseline.sh` from your computer. All three HTTP endpoints must return `200`, the ALB target must report `healthy`, and the script must finish with:

```text
healthz: 200
readyz: 200
catalog: 200
Baseline healthy: PASS
```

For a closer look, you can also test the actual ALB URL:

```bash
ALB=$(terraform -chdir=terraform output -raw alb_url)
curl -i --connect-timeout 5 --max-time 12 "$ALB/healthz"
curl -i --connect-timeout 5 --max-time 12 "$ALB/readyz"
curl -i --connect-timeout 5 --max-time 12 "$ALB/catalog"
```

The `/catalog` response should contain the Shop catalogue data. Confirm Session Manager access and the expected S3 object when required by an incident. An EC2 instance showing `running`, or even an ALB target showing `healthy`, does not by itself prove your computer can reach the application.

**If the target is healthy but your external requests time out:** compare the public IPv4 address returned by `curl -4 https://checkip.amazonaws.com` with `allowed_http_cidrs` in `terraform/terraform.tfvars`. Correct the CIDR, review a new Terraform plan, apply only the intended security-group change, and rerun `scripts/validate-baseline.sh`.

**Begin incident injection only when the required baseline checks pass.**

If any check fails, investigate the setup error before introducing a new fault. You can use the troubleshooting reminder in the book and the [lab operating notes](docs/troubleshooting-labs.md).

## 4. Work through one incident

Open the specific incident README first. For example, to try Incident 03:

```bash
cat labs/incident-03/README.md
scripts/validate-baseline.sh
export CONFIRM_LAB_CHANGES=YES
scripts/incident.sh 03 setup
scripts/incident.sh 03 inject
scripts/incident.sh 03 status
```

The `setup` action checks prerequisites, `inject` creates a controlled change, and `status` shows initial state. **Stop here and investigate.** Follow Incident 03 in the book to collect and interpret evidence, decide on a repair, and verify the original symptom.

After the investigation (or if you need to stop), follow the same guide's reset instructions:

```bash
scripts/incident.sh 03 reset
scripts/validate-baseline.sh
```

Some controls return a **Systems Manager command ID**. A command ID proves submission, not successful execution; check the returned command's status before assuming the change happened. See [the SSM example](docs/troubleshooting-labs.md).

Incidents **01, 07, 09 and 10** use additional or different commands. Their incident guides provide the correct entry and safe-exit steps.

## 5. Locate your actual AWS resources

The book uses illustrative identifiers. The deployed labs generate names and IDs for your account. Use the actual values rather than copying the book's example names verbatim:

```bash
terraform -chdir=terraform output
scripts/show-resources.sh
```

For Incident 07, run `scripts/prepare-incident-07.sh` after creating the shared Shop environment to generate a private example configuration from your own resources. Check the values before deployment.

## 6. Use the AWS Console alongside the CLI

CLI commands are convenient for recording evidence. The same general resources can be inspected visually in the **same AWS Region**:

| What to inspect | Console navigation |
|---|---|
| EC2 server or Session Manager | EC2 → Instances → select instance → Connect → Session Manager |
| Auto Scaling group activity | EC2 → Auto Scaling Groups → Activity |
| Load balancer / target health | EC2 → Load Balancers / Target Groups → Targets |
| S3 catalogue and versions | Amazon S3 → Buckets → Objects → Show versions |
| IAM role permissions | IAM → Roles → select the instance role |
| CloudWatch alarm | CloudWatch → Alarms |
| CloudFormation changes | CloudFormation → Stacks → Events / Resources |

Console names and navigation can change. A resource status is an observation; verify the original application requirement as well.

## 7. Reset an incident or delete the environment

**Reset** returns an individual exercise to a usable state. **Delete** removes the practice resources when you are finished. They are different operations.

Reset any injected faults and capture any evidence you want to retain. For Incident 07, destroy its separate Terraform module **before** deleting the shared Shop networking. For Incidents 01 and 09, delete their own CloudFormation stacks using the incident guides.

For the shared environment, preview what Terraform would remove:

```bash
terraform -chdir=terraform plan -destroy
```

Once you confirm it affects only your lab, run:

```bash
terraform -chdir=terraform destroy
```

The versioned S3 bucket may need its older versions and delete markers removed before Terraform can delete it. Follow [COSTS.md](COSTS.md) and the [cleanup guide](docs/cleanup-guide.md). Keep the original Terraform state until AWS resource removal is confirmed. If state was lost, use the [lost-state guidance](docs/LOST_TERRAFORM_STATE_CLEANUP.md) rather than expecting a new state file to discover existing resources.

After cleanup, verify in AWS that no lab EC2 instances, Auto Scaling groups, load balancers, S3 buckets, CloudFormation stacks or alarms remain. Charges may continue while resources exist.

## Repository guide

```text
aws-incident-troubleshooting-labs/
├── README.md                 Start here
├── PREREQUISITES.md          AWS access and required tools
├── COSTS.md                  Cost and cleanup guidance
├── application/              Shop application
├── terraform/                Shared Shop infrastructure
├── cloudformation/           Separate CloudFormation exercises
├── labs/incident-01..10/     Incident-specific instructions
├── scripts/                  Setup, inspection and reset controls
├── docs/                     Additional operational guidance
└── evidence/                 Private evidence note guidance
```

Read [the incident index](labs/README.md) for all ten exercises. The repository's instructions cover how to create and reset failures; the book provides the complete investigation and engineering reasoning. **This repository is optional, but hands-on practice is strongly encouraged wherever you have a suitable AWS sandbox.**
