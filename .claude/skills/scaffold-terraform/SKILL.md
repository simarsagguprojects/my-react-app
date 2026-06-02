---
name: scaffold-terraform
description: This skill is used to create or update terraform files in `terraform/` folder
allowed-tools: Read, Write,Grep, Glob
disable-model-invocation: true
---
Create terraform files in `my-react-app/terraform/` by referring the `template-spec.md` from current skill directory.

# Actions to take
Create `main.tf`,`outputs.tf`,`inputs.tf`, `variables.tf`, `providers.tf`, `backend.tf` in `terraform/` and referring specifications from `template-spec.md`
Ensure there are no syntax errors in these files.

# After action is complete
[] verify if all the required files are created.
[] verify if there is any syntax error
[] summarise the resources created
[] Suggest running `/tf-plan` skill