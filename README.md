# aws-dms
AWS Docker Micro Services

#Description

Micro Service is based on a Docker image that is build using GitHub Workflow and push to a AWS ECR Registry.
The Image is deployed using a Blue/Green strategy into a ECS Cluster based on AWS Fargate.
There are three terraform projects each one on a different folder inside terraform.
Code Pipeline contains the definition to support the Git Hub Workflow.
ECS is the Elastic Container Cluster where the Micro Service is deploy.
IAM has is used to create the necesary users and roles for the project to run.
IAM needs to be executed with a user with enough previlege to create new users and roles.


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