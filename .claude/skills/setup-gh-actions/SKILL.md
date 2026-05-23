---
name: setup-gh-actions
description: This skill allows you to create/validate GitHub Actions workflow
allowed-tools: Read, Grep, Glob, Write
disable-model-invocation: true
---

This skill creates and validates the GitHub Actions workflow in `.github/workflows`

# Action to take
1. Create a `deploy.yml` workflow that automatically invokes on push to `main` branch of this repository.
2. Make sure you are in `my-react-app` directory. 
3. Install Docker.
4. Create a docker image and run the builder stage and copy build folder out 
   1. docker build --target builder -t react-app-builder . 
   2. docker run --name react-container react-app-builder sh -c "npm ci && npm run build"
   3. docker cp react-container:/app/build ./build
   4. docker rm react-container
5. Check if `./build ` exists locally.
6. Assume `github-actions-deploy` AWS OIDC provider role to run AWS commands.
7. Upload to S3 : aws s3 sync ./build s3://react-app-bucket --delete
8. Invalidate cache for `react-app-cdn` CloudFront CDN.
9. Send email notifications to me on failure of the workflow.
10. Raise if any of the above step fails.

# Post-action verification
[] Validate syntax of this workflow.
[] Ensure that `/build` folder exists in `react-app-bucket` S3 bucket.
[] Raise an Error if any of the resource is in FAILED/ERROR state.
[] Recommend secure practises for this workflow.