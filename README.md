# aws-dms
AWS Docker Micro Services

#Description

AWS-DMS is a POC to run docker microservice on AWS. The project has a build process to push the image to AWS ECR Registry.
The Image is deployed using a Blue/Green strategy into a ECS Cluster based on AWS Fargate.
All the infra is provisioned with Terraform.

#Running the Microservice Locally
##Local Docker Build
```
docker build -t dms .
```
##Local Docker Run
```
docker run -p 8080:8080 dms
```
##Local Test Run
```

```