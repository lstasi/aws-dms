# AWS DMS
AWS Docker Micro Services

# Description

AWS-DMS is a POC to run docker microservice on AWS. The project has a build process to push the image to AWS ECR Registry.
The Image is deployed using a Blue/Green strategy into an ECS Cluster based on AWS Fargate.
All the infra is provisioned with Terraform.
For this POC the Docker Microservice is based on Python 3.8 and using Flask as microframework.

# Getting Started
First Fork the Project and Clone.
You will need to export AWS credentials as environment variables, and a GitHub personal token to connect from AWS.
To generate a Personal Access Token: https://github.com/settings/tokens
```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION=""
export GIT_HUB_TOKEN=""
```

# Terraform
Terraform version: v0.14.10

Run terraform from terraform/ecs
```
terraform apply
```

# CI Continous Integration
To Build the application you only need to commit and push.

# Manual Build
You can also build by running AWS build start command.
```
aws codebuild start-build --project-name dms-build
```

# Deploy Pipeline
After build is completed a new image is push to ECR
The new image will trigger the Pipeline that deploy the Docker into ECS
You can also run the deploy process manually using this command
```

```
# Running the Microservice Locally
## Local Docker Build
```
docker build -t dms .
```
## Local Docker Run
```
docker run -p 8080:8080 dms
```
## Local Test Run
```
pip install -r requirements.txt
python src/app_test.py
```