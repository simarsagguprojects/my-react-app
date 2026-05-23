# Terraform for AWS resources

Create all the files mentioned below in `/terraform` folder with mentioned configuration

## main.tf
Tag following resources with AppName as `claude-react-app` and Env as `Prod`
1. Create a`react-app-bucket` s3 bucket with following configuration
   1. allow public access.
   2. put bucket policy to only allow get object to all and allow all read actions to SmartSimar user and explicit deny rest of the actions.
   3. Bucket policy should allow OIDC provider created role `github-actions-deploy` to read and write to the bucket.
   4. Set server-side logging to `react-app-bucket-access-logs`.
   5. enable bucket versioning.
   6. choose AES256 bucket encryption.
   7. enable Static website hosting and set index.html as index document. 
2. Create a `react-app-bucket-access-logs` bucket
  block public access.
   1. Put bucket policy to only allow get object to only root user have full access to this bucket. 
   2. enable bucket versioning 
   3. choose AES256 bucket encryption. 
3. Create a CloudFront distribution `react-app-cdn` with following configuration
   1. Choose the "Web" distribution method.
   2. Choose "main.html" as root object.
   3. Choose `react-app-bucket` bucket as Origin Domain Name.
   4. Choose Price class: PriceClass_200.
   5. Set Viewer Protocol Policy: Choose HTTPS.
   6. Default settings for Cache Behaviour settings.
   7. Use a REST API endpoint as the origin, and restrict access with an origin access control (OAC).
4. Create `github-actions-deploy` AWS OIDC provider role which will be assumed by Github Actions deploy.yml file to deploy this project to s3 bucket.

## outputs.tf
Create output variables: cloudfront_distribution_id, cloudfront_domain_name, s3_bucket_name, s3_bucket_arn, access_log_s3_bucket_name, access_log_s3_bucket_arn

## variables.tf
Create variables: AppName(`claude-react-app`),Env(`Prod`), Region(`ap-south-1`)

## providers.tf
1. Create this file with required provider, choose source as AWS and required_version >= 1.1. 
2. Create Region variable with `ap-south-1`.