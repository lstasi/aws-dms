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
export AWS_ACCESS_KEY_ID="RANDOM_KEY_ID"
export AWS_SECRET_ACCESS_KEY="SECRET_KEY_ID"
export AWS_DEFAULT_REGION="us-east-1"
export TF_VAR_GITHUB_TOKEN="SECRET_PERSONAL_TOKEN"
export TF_VAR_REPO_URL="http://gihub.com/user/repo"
```

# Terraform
Terraform version: v0.14.10

Run terraform from terraform/dms
```
terraform apply
```

# CI/CD Continuous Integration Continuous Deploy
To Build and Deploy the application, you only need to commit and push.

# PipeLine
Each time a new commit is push into the main branch, AWS Code Build is triggered running the build spec definitions in buildspec.yml
The build runs Unit test and if they are all green a new Docker image is build and push to ECR.
Then when Code Pipeline detects there is a new Docker image, the image is deployed into the ECS Cluster using a Blue/Green Deploy.
```
GitHub -> AWS CodeBuild -> AWS ECR -> AWS CodePipeline -> AWS ECS Blue/Green Deploy
```

# Manual Build and Deploy trigger
You can also build by running AWS build start command.
```
aws codebuild start-build --project-name dms-build
```

# Deploy Pipeline
After build is completed a new image is push to ECR
The new image will trigger the Pipeline that deploy the Docker into ECS
You can also run the deployment process manually using this command
```
aws codepipeline start-pipeline-execution --name dms-pipeline
```
# Running the Microservice Locally
## Local Docker Build
```
docker build -t dms .
```
## Local Docker Run
```
docker run -p 8080:8080 -e FLASK_ENV=development dms
```
## Local Docker Run DynamoDB
```
docker run -p 8000:8000 amazon/dynamodb-local
```
## Local Docker Run Composer App + DynamoDB
```
docker-composer up
```


## Local Test Run
```
pip install -r requirements.txt
pytest
```

## Local Run App
```
FLASK_ENV=development END_POINT=http://localhost:8000 python src/app.py
```
## Local API Testing
```
http://localhost:8080/init_db
http://localhost:8080/get_movie/Matrix/1999
http://localhost:8080/put_movie/TheMatrix/1999/Matrix/5
http://localhost:8080/get_movie/TheMatrix/1999
```


# TO-DO
- [ ] Move Roles to IAM project
- [ ] Add https support
- [ ] Setup WAF Policies for ECS
- [X] Create NAT Gateway and Move ECS Subnets to private
- [ ] Add new Staging environment step to the Pipeline
