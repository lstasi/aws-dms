# AWS DMS
AWS Docker Micro Services

# Description

AWS-DMS is a POC to run docker microservice on AWS. The project has a build process to push the image to AWS ECR Registry.
The Image is deployed using a Blue/Green strategy into an ECS Cluster based on AWS Fargate.
All the infra is provisioned with Terraform.
For this POC the Docker Microservice is based on Python 3.8 and using Flask as microframework.

# Getting Started
Clone the project and just run terraform to deploy.
You will need to export AWS credentials as environment variables, and a GitHub personal token to connect from AWS.
```
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export GIT_HUB_TOKEN=""
```

# Terraform
Terraform version: v0.14.10

Run terraform from terraform/ecs
```
terraform apply
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