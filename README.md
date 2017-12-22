The CloudFormation templates in this directory set up www-test.bu.edu infrastructure - the test landscape for the 
core bu.edu web service.  It is split into multiple templates for two reasons: 1) because they are various quick
starts, examples, and reference architectures stiched together; and 2) I wanted to start separating by role
(3-iam.yaml has everything that InfoSec would manage).

The templates should be run in the following order:

- need to create the basic account stuff and the initial keypair.
- 1-vpc - creates the core VPC configuration
- 2-deployment-base - creates the basic ECR and S3 buckets - needs to be done before iam so the S3 buckbets can be referenced
- 3-iam - all security groups and IAM roles 
- 4-ecs-buedu (rename) - application load balancer and ECS cluster
- Run 5-deploy-buedu to store ecs-buedu-service.yaml in a Zip and upload to the S3 bucket (this still needs to be made generic - has a hardcoded bucket name)
- 6-deployment-pipeline - The CodeBuild, CodePipeline, and CodeDeploy definitions which does the automatic release when the GitHub repo is updated.  The pipelines uses the zipped ecs-buedu-service to manage release.
- 7-cloudfront.yaml - sample CloudFront distribution to be used as an example.

The templates in this directory are based on the following sources:

- http://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/quickref-ecs.html
- https://aws.amazon.com/blogs/compute/continuous-deployment-to-amazon-ecs-using-aws-codepipeline-aws-codebuild-amazon-ecr-and-aws-cloudformation/

Eventually we will incorporate items from the following sources:

- http://docs.aws.amazon.com/codebuild/latest/userguide/how-to-create-pipeline.html#how-to-create-pipeline-add-test
- https://aws.amazon.com/blogs/aws/codepipeline-update-build-continuous-delivery-workflows-for-cloudformation-stacks/
- http://docs.aws.amazon.com/codecommit/latest/userguide/how-to-migrate-repository-existing.html
- https://sanderknape.com/2016/06/getting-ssl-labs-rating-nginx/ 
- https://aws.amazon.com/blogs/compute/continuous-deployment-for-serverless-applications/
- https://github.com/awslabs/aws-waf-security-automations
- https://sanderknape.com/2017/06/infrastructure-as-code-automated-security-deployment-pipeline/
- https://github.com/andreaswittig/codepipeline-codedeploy-example


Various methods to test with CodePipeline:
- https://aws.amazon.com/blogs/devops/implementing-devsecops-using-aws-codepipeline/

How to do this with an external continuous integration other than CodePipeline (CircleCI):
- https://circleci.com/docs/1.0/continuous-deployment-with-aws-ec2-container-service/

Here are some documents used for how to handle redirection:

https://aws.amazon.com/blogs/compute/build-a-serverless-private-url-shortener/ (S3 redirect single URLs)


aws --profile webpoc cloudformation validate-template --template-body file:///home/dsmk/projects/docker-bufe-buedu/aws/iam.yaml

VPC: This can be done with the CLI doing something like:

aws --profile webpoc cloudformation create-stack --template-body file://1-vpc.yaml --tags file://non-prod-vpc-tags.json --parameters file://non-prod-vpc-parameters.json --stack-name vpctest
