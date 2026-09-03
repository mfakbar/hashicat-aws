# HashiCat on AWS

A small Terraform template for workshops, demonstrations, and infrastructure testing. It provisions a public AWS EC2 instance, installs Apache, and serves a customizable **Meow World** web page.

> This is intentionally simple, legacy lab code. It creates billable AWS resources and is not hardened for production use.

## What this repository is

HashiCat is a disposable example application for learning and testing the Terraform workflow:

```text
Terraform configuration -> AWS infrastructure -> Apache bootstrap -> Meow World page
```

It demonstrates how Terraform can:

- accept input variables;
- create related AWS networking and compute resources;
- generate and register an SSH key;
- run a provisioning script on a new EC2 instance;
- expose useful values through Terraform outputs;
- store state locally or in an HCP Terraform workspace.

The `exercises/` directory contains starter and completed Terraform files for guided workshops. The root configuration is the completed runnable example.

## Use cases

Use this repository as a short-lived test target for:

- Terraform `init`, `validate`, `plan`, `apply`, and `destroy` practice;
- HCP Terraform remote-state or remote-run workshops;
- testing variable changes and output values;
- demonstrating resource dependencies and provisioning;
- CI experiments that validate Terraform configuration;
- confirming that temporary AWS credentials and permissions work.

Do not use it as a production web-server pattern.

## What it creates

| Resource | Purpose |
| --- | --- |
| VPC and subnet | Isolated network for the test instance |
| Internet gateway and route table | Public internet connectivity |
| Security group | Allows inbound SSH, HTTP, and HTTPS |
| TLS private key and AWS key pair | Lets Terraform provision the instance over SSH |
| Elastic IP | Gives the instance a stable public address |
| Ubuntu EC2 instance | Hosts the sample application |
| Apache web server | Serves the generated `Meow World` page |

After deployment, Terraform returns the public hostname and IP address as `catapp_url` and `catapp_ip`.

## How it works

1. Terraform creates the VPC, subnet, route, security group, key pair, Elastic IP, and EC2 instance.
2. The `null_resource.configure-cat-app` provisioner connects to the instance over SSH.
3. Terraform copies `files/deploy_app.sh` to the instance.
4. The provisioner installs Apache and runs the script with the selected prefix, image source, width, and height.
5. The script writes `/var/www/html/index.html`.
6. The output URL opens the resulting test page.

## Prerequisites

You need:

- an AWS account and credentials allowed to create the resources listed above;
- Terraform CLI and, for the local authentication example below, AWS CLI;
- network access from your machine or HCP Terraform runner to AWS;
- an HCP Terraform account only if you want remote state or remote execution.

The configuration pins AWS provider `3.42.0` and uses Ubuntu 18.04. Keep those versions for workshop reproducibility, or modernize and retest them before adapting the template.

## Quick start

### 1. Clone the repository

```bash
git clone https://github.com/mfakbar/hashicat-aws.git
cd hashicat-aws
```

### 2. Choose where Terraform stores state

Terraform loads every `*.tf` file in the directory. The included `remote_backend.tf` points to the original workshop organization and workspace, so choose one of these options before running `terraform init`.

For a simple local test, rename the remote-backend file so Terraform ignores it:

```bash
mv remote_backend.tf remote_backend.tf.disabled
```

For HCP Terraform, edit `remote_backend.tf` and replace the organization and workspace names with your own, then authenticate:

```bash
terraform login app.terraform.io
```

If the HCP workspace performs remote runs, configure the AWS credentials and Terraform variables in that workspace rather than relying on your local shell.

### 3. Configure AWS credentials

For a local run, authenticate with your preferred AWS CLI profile or environment-variable method and verify the active identity:

```bash
aws sts get-caller-identity
```

### 4. Set the required variable

Create a local `terraform.tfvars` file. The repository ignores `*.tfvars` files so test-specific values are not committed accidentally.

```hcl
prefix = "my-hashicat-test"
region = "us-east-1"
```

Optional variables include `instance_type`, `address_space`, `subnet_prefix`, `placeholder`, `width`, and `height`. See `variables.tf` for defaults.

### 5. Initialize, review, and deploy

```bash
terraform init
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Always review the plan before applying it. A successful apply prints URLs similar to:

```text
catapp_url = "http://ec2-...compute.amazonaws.com"
catapp_ip  = "http://203.0.113.10"
```

Open either URL to view the sample page.

### 6. Test a change

Change `prefix`, `placeholder`, `width`, or `height` in `terraform.tfvars`, then run another plan and apply. The `timestamp()` trigger intentionally causes the provisioning step to run on every apply, making the repository useful for demonstrations but preventing a permanently empty plan.

### 7. Clean up

Destroy the lab as soon as testing is complete:

```bash
terraform destroy
```

Review the destroy plan and enter `yes`. Confirm in AWS that the EC2 instance, Elastic IP, key pair, security group, subnet, route table, internet gateway, and VPC have been removed.

## Expected outcome

You should have a temporary public website backed by a Terraform-managed EC2 instance, plus a state file that records the deployed infrastructure. The exercise provides a visible result while keeping the Terraform configuration small enough to understand during a workshop.

## Lab limitations and security notes

- The security group opens ports 22, 80, and 443 to `0.0.0.0/0`. Restrict SSH to a trusted source address before applying, even in a lab.
- The generated SSH private key is stored in Terraform state. Protect local and remote state as sensitive data.
- The site uses HTTP and does not configure TLS, even though port 443 is open.
- Remote provisioners depend on SSH and package repositories being available. They are useful for this exercise but should not be the default application-delivery mechanism in production.
- The Elastic IP, EC2 instance, and public IPv4 address may incur AWS charges.
- `admin_username` is currently unused.
- The remote backend uses legacy `backend "remote"` syntax retained for workshop compatibility. Current HCP Terraform projects may prefer the `cloud` block.

## Repository layout

```text
.
├── main.tf                 # AWS resources and EC2 provisioning
├── variables.tf            # Required and optional inputs
├── outputs.tf              # Public application URLs
├── remote_backend.tf       # Original HCP Terraform backend example
├── files/deploy_app.sh     # Writes the Apache sample page
└── exercises/              # Workshop starter and completed files
```

## References

- [Terraform AWS getting-started tutorials](https://developer.hashicorp.com/terraform/tutorials/aws-get-started)
- [Terraform core workflow](https://developer.hashicorp.com/terraform/tutorials/cli/apply)
- [Terraform remote backend](https://developer.hashicorp.com/terraform/language/backend/remote)
- [Terraform provisioners](https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax)
- [AWS security-group guidance](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)

## License

Licensed under the [Apache License 2.0](./LICENSE).
