# Session 4 — Bootstrap Remote State + Migration

A two-root Terraform project that provisions an S3 + DynamoDB remote state backend, migrates an existing local state file to S3, and proves the DynamoDB lock prevents concurrent applies.

## What students learn

- Why the S3 bucket that stores state must live in a separate Terraform root (`infra/bootstrap/`) from the workload root that uses it
- How `lifecycle { prevent_destroy = true }` protects the state backend from accidental deletion
- Why the DynamoDB lock table requires `LockID` as its hash key — the exact string the S3 backend expects
- Why backend values in `backend.tf` must be hardcoded strings (not variables or locals)
- How `terraform init` migrates existing local state to a new remote backend with a single prompt
- How DynamoDB serializes concurrent `terraform apply` runs and what the lock error looks like

## Project structure

```
infra/                          # workload root — uses the remote backend
├── backend.tf                  # S3 backend config (written after bootstrap outputs)
├── main.tf
├── provider.tf
├── variables.tf
├── envs/
│   └── dev/
│       └── dev.tfvars
└── bootstrap/                  # separate root — provisions the backend itself
    ├── main.tf
    ├── outputs.tf
    ├── provider.tf
    ├── variables.tf
    └── terraform.tfvars
```

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) ≥ 1.8
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) configured with credentials that can create S3 buckets and DynamoDB tables

---

## Demo workflow

### 1. Explore the project structure

```bash
tree infra/
```

`infra/` and `infra/bootstrap/` are two independent Terraform roots — each has its own state and its own `terraform init`.

### 2. Write the bootstrap module

Fill in `infra/bootstrap/variables.tf`, `infra/bootstrap/main.tf`, and `infra/bootstrap/outputs.tf`.

`main.tf` provisions three resources:

```hcl
resource "aws_s3_bucket" "state" {
  bucket = "${var.team_name}-tfstate"
  lifecycle { prevent_destroy = true }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "locks" {
  name         = "${var.team_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  lifecycle { prevent_destroy = true }
}
```

`outputs.tf` exposes `state_bucket` and `lock_table`.

### 3. Bootstrap: init

```bash
cd infra/bootstrap
terraform init
```

There is no `backend` block in `bootstrap/` — it uses local state intentionally. The state backend cannot manage its own storage.

### 4. Bootstrap: apply

```bash
terraform apply -auto-approve
```

Expected output:

```
aws_s3_bucket.state: Creating...
aws_dynamodb_table.locks: Creating...
aws_s3_bucket_versioning.state: Creating...
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### 5. Read bootstrap outputs

```bash
terraform output
```

Expected output:

```
lock_table  = "pdds-oyd-2026-session4-demo4-terraform-locks"
state_bucket = "pdds-oyd-2026-session4-demo4-tfstate"
```

Copy these values — you will paste them into `infra/backend.tf` in the next step.

### 6. Write `infra/backend.tf`

```hcl
terraform {
  backend "s3" {
    bucket         = "pdds-oyd-2026-session4-demo4-tfstate"
    key            = "workspace/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "pdds-oyd-2026-session4-demo4-terraform-locks"
    encrypt        = true
  }
}
```

The values must be hardcoded strings — the S3 backend does not accept Terraform variables or locals.

### 7. Migrate local state to S3

```bash
cd ../
terraform init
```

Terraform detects the new backend and prompts:

```
Do you want to copy existing state to the new backend?
```

Answer `yes`. After migration:

```
Successfully configured the backend "s3"!
Terraform has been successfully initialized!
```

The local `terraform.tfstate` file is now obsolete. Add it to `.gitignore`.

### 8. Verify state is in S3

```bash
aws s3 ls s3://pdds-oyd-2026-session4-demo4-tfstate/workspace/
aws s3api get-bucket-versioning --bucket pdds-oyd-2026-session4-demo4-tfstate
```

### 9. Prove DynamoDB locking (two-terminal demo)

The `time_sleep` resource in `infra/main.tf` holds the DynamoDB lock for 30 seconds, long enough to trigger a conflict from a second terminal.

**Terminal 1** — start an apply:

```bash
terraform apply -var-file=envs/dev/dev.tfvars -auto-approve
```

As soon as you see `time_sleep.demo_lock: Creating...`, switch to Terminal 2.

**Terminal 2** — attempt a concurrent apply against the same root:

```bash
cd infra
terraform apply -var-file=envs/dev/dev.tfvars -auto-approve
```

Expected error:

```
Error: Error acquiring the state lock

  Lock Info:
    ID:        <uuid>
    Path:      pdds-oyd-2026-session4-demo4-tfstate/workspace/terraform.tfstate
    Operation: OperationTypeApply
    Who:       user@host
    ...

  DynamoDB state locking failed: ConditionalCheckFailedException
```

This error comes from DynamoDB — not from a local file. The lock table serialized access to the shared state file.

### 10. List state resources

After Terminal 1's apply completes:

```bash
terraform state list
```

### 11. Clean up

```bash
# Remove the sleep resource before destroying (avoids another 30s wait)
cd infra
terraform state rm time_sleep.demo_lock
terraform destroy -var-file=envs/dev/dev.tfvars -auto-approve

# Tear down the backend — remove lifecycle blocks first
cd bootstrap
# Edit main.tf: delete both  lifecycle { prevent_destroy = true }  blocks
terraform destroy -auto-approve
```

---

## Expected outcomes

By the end of this demo, students should be able to:

1. Explain why the S3 backend must be provisioned by a separate `bootstrap/` root
2. Identify which DynamoDB attribute name the S3 backend requires and why
3. Migrate an existing local-state root to a remote S3 backend using `terraform init`
4. Demonstrate that DynamoDB prevents concurrent applies with a `ConditionalCheckFailedException`
5. Safely tear down a backend that has `prevent_destroy = true` lifecycle rules
