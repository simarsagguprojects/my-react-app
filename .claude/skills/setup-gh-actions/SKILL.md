---
name: setup-gh-actions
description: This skill allows you to create/validate GitHub Actions workflow
allowed-tools: Read, Grep, Glob, Write
disable-model-invocation: true
argument-hint: [create|validate|update]

---

This skill creates, validates and updates the GitHub Actions workflow in `.github/workflows`

If $ARGUMENTS contains "create", generate the complete workflow file.
If $ARGUMENTS contains "validate", only validate the existing file.
If $ARGUMENTS contains "update", update the workflow according to actions defined in this file.

# Action to take
1. Create a `deploy.yml` workflow that automatically invokes on push to `main` branch of this repository if not created.
2. Make sure you are in `my-react-app` directory. 
3. Install Docker
4. Create a docker image.
   1. docker build --target builder -t react-app-builder . 
5. The unit test cases from `src/tests/App.test.js` should always pass.
   1. docker run --name react-container react-app-builder sh -c "npm ci && npm test -- --watchAll=false --ci"
6. Run the builder stage and copy build folder out 
   1. docker run --name react-container react-app-builder sh -c "npm ci && npm run build"
   2. docker cp react-container:/app/build ./build
   3. docker rm react-container
7. Check if `./build ` exists locally.
8. Assume `github-actions-deploy` AWS OIDC provider role to run AWS commands.
9. Upload to S3 : aws s3 sync ./build s3://react-app-bucket --delete
10. Invalidate cache for `react-app-cdn` CloudFront CDN. 
11. Raise if any of the above step fails.

# Post-action verification
[] Validate syntax of this workflow.
[] Ensure that `/build` folder exists in `react-app-bucket` S3 bucket.
[] Raise an Error if any of the resource is in FAILED/ERROR state.
[] Recommend secure practises for this workflow.
[] Make sure `deploy.yml` defined steps match with this file. 