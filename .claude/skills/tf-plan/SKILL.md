---
name: tf-plan
description: This skill allows you to preview the changes Terraform will make before you apply them.
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Action to take
Make sure you are in `my-react-app` directory
1. Run `terraform init` to initialize the Terraform configuration.
2. Run `terraform plan` to verify and preview the changes Terraform will make.

# Post-action verification
[] Summarise all the changes/updates that will be created by Terraform
[] Remind to run `/tf-apply` to apply the changes to AWS environment
[] Raise an Error if there is any error during terraform plan stage and recommend the fixes as well.