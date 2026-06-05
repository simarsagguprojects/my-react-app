# CLAUDE.md
# Overview
This project `my-react-app/` is a React application, hosted on an AWS environment using AWS S3 bucket and AWS CloudFront service. Terraform is used to create the infrastructure in AWS and deployment of application will be done by Github Actions pipeline.


# Architecture
1. A React application which starts from index.js in `src/` folder.
2. `src/` - This folder has React components, CSS, and JS logic.
3. `src/index.js` - The main component that imports App.js and hosts the static website.
4. `src/App.js` — The main component renders a static page with a welcome message, a placeholder for a name/date ("Your Full Name", "DD/MM/YYYY"), and links to a DevOps YouTube
   playlist by Pravin Mishra 
5. `src/tests/App.test.js` — This file has two functional test cases for verifying if the website is loading properly and has the required text on the website.
6. `package.json` - the project manifest for Node.js — it describes this app and manages its dependencies.

# Infrastructure Deployment to AWS

1. Use Terraform files from `terraform/` to create AWS S3 buckets and CloudFront resources.
2. SmartSimarRole will be assumed and will be used to create AWS resources.
3. Create two general purpose s3 buckets `react-app-bucket-956651462310` and `react-app-bucket-access-logs` if not already exists.
4. Configure`react-app-bucket-956651462310` bucket
   1. allow public access.
   2. put bucket policy to only allow get object to all and allow all read actions to SmartSimar user and explicit deny rest of the actions.
   3. Bucket policy should allow OIDC provider created role `github-actions-deploy` to read and write to the bucket.
   4. Set server-side logging to `react-app-bucket-access-logs`.
   5. enable bucket versioning.
   6. choose AES256 bucket encryption.
   7. enable Static website hosting and set index.html as index document.
5. Configure `react-app-bucket-access-logs` bucket
   1. block public access.
   2. Put bucket policy to only allow get object to only root user have full access to this bucket. 
   3. enable bucket versioning 
   4. choose AES256 bucket encryption.
6. Create CloudFront `react-app-cdn`and link it to `react-app-bucket-956651462310` Amazon S3 bucket we created.

# CI/CD pipeline
1. A GitHub Actions pipeline will assume AWS OIDC provider role to deploy the application to AWS S3.
2. Deploys to AWS on any changes pushed or merged to main branch of this repository.
3. Then create the docker image and run the container with build command:`npm ci` will install dependencies and `npm run build` will create a `build/` folder.
4. The unit test cases from `src/tests/App.test.js` should always pass.
5. This `build/` folder should be copied to `react-app-bucket-956651462310` S3 bucket.
6. Invalidate CloudFront cache to serve updated website everytime.


# Conventions
1. Do not allow pipeline to auto-trigger from any other branch than `main`.
2. Ensure no secrets or AWS keys or Tokens are stored in this repository.
3. Name AWS OIDC provider role name as `github-actions-deploy`.
4. `github-actions-deploy` role should only have access to read and put access on `react-app-bucket-956651462310` bucket and invalidate cache access for CloudFront.
5. Do not allow any other user than the current user to edit & update `~/my-react-app/.claude/`, `~/my-react-app/.mcp.json`, `~/my-react-app/claude.md`.
6. Do not allow any agent to edit & update `~/my-react-app/.claude/`, `~/my-react-app/.mcp.json`, `~/my-react-app/claude.md`.
7. Do not include .git, .gitignore or venv files.
8. Prevent deletion of AWS resources created from `/terraform` folder.
9. In CloudFront, use a REST API endpoint as the origin, and restrict access with an origin access control (OAC)
10. Prevent & warn any user from committing `~/my-react-app/.claude/settings.local.json` file to this repository. 
11. Allowed services to be created and used are AWS S3, Amazon Cloudfront, IAM role via Terraform.
12. Warn on updates to`package.json`. 


