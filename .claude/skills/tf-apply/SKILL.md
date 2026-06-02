---
name: tf-apply
description: This skill allows you to apply the changes to AWS environment
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Action to take
Make sure you are in `my-react-app` directory 
Run `terraform apply -auto-approve` to apply the Terraform changes to AWS environment

# Post-action verification
[] Summarise all the resources created/updated in AWS environment.
[] Ensure all the deployed resources have no errors.
[] Raise an Error if any of the resource is in FAILED/ERROR state.