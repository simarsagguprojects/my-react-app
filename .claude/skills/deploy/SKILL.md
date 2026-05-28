---
name: deploy
description: This skill allows you to sync `my-react-app` project's `/build` folder generated after `npm ci && npm run build` to AWS S3 bucket and invalidate CloudFront cache
allowed-tools: Read, Grep, Glob, Bash
disable-model-invocation: true
---

# Action to take
1. Make sure you are in `my-react-app` directory. 
2. Make sure Docker is running else raise.
4. Create a docker image.
   1. docker build --target builder -t react-app-builder . 
5. The unit test cases from `src/tests/App.test.js` should always pass.
   1. docker run --name react-container react-app-builder sh -c "npm ci && npm test -- --watchAll=false --ci"
6. Run the builder stage and copy build folder out 
   1. docker run --name react-container react-app-builder sh -c "npm ci && npm run build"
   2. docker cp react-container:/app/build ./build
   3. docker rm react-container
4. Check if `./build ` exists.
5. Assume `github-actions-deploy` AWS OIDC provider role to run AWS commands.
6. Upload to S3 : aws s3 sync ./build s3://react-app-bucket --delete
7. Invalidate cache for `react-app-cdn` CloudFront CDN.
8. Raise if any of the above step fails.

# Post-action verification
[] Summarise all the actions taken in AWS environment.
[] Ensure that `/build` folder exists in `react-app-bucket` S3 bucket.
[] Raise an Error if any of the resource is in FAILED/ERROR state.