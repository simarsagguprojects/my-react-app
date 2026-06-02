---
name: tf-apply
description: This skill allows you to apply the changes to AWS environment
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Action to take
Make sure you are in `my-react-app` directory 
Run `terraform apply -auto-approve` to apply the Terraform changes to AWS environment
Run AWS S3 CLI command to copy `~/terraform/*.tfstate`, `~/terraform/*.tfstate.backup` from `my-react-app` to `react-app-terraform-state-956651462310` bucket.

# Post-action verification
[] Summarise all the resources created/updated in AWS environment.
[] Ensure all the deployed resources have no errors.
[] Raise an Error if any of the resource is in FAILED/ERROR state.