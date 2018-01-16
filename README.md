Starting to look into using nested stack sets for some of this.  This means that the CF templates need to
be stored in an S3 bucket.  This approach uses the approach similar to:

https://github.com/awslabs/ecs-refarch-continuous-deployment

This means that one of the first things we need to do is run the deploy script to create, configuration, and
update the S3 bucket that contains the CF templates.  Once that is done one can run cloudformation referencing 
the S3 bucket location.  This requires the following changes to the process:

1. separate the settings files into separate trees from the templates.
2. put the templates all in a single tree in bucket/templates/landscape/
3. move the parameters into separate directories.

These CloudFormation templates are used to provision and manage the BU IS&T Web2Cloud phase 1 project
infrastructure.  Each subdirectory is a different cloudformation stack to be run independently due to
lifecycle, number, or policy.  Some of them export values to be used by other stacks (for example, vpc).

Each subdirectory has a settings subdirectory to store parameters and tags for specific instances of the 
stack.  

It consists of the following stacks:

- account : account level settings irrespective of landscape (web2cloud-prod, and web2cloud-nonprod).
- vpc : this stack builds the VPC and conditionally VPN connections back to campus (web2cloud-prod, web2cloud-nonprod, and sandbox).
- base-landscape : this contains the common per landscape elements (basic ECR and S3 buckets) 
  (buaws-webfe-base-syst, buaws-webfe-base-devl, buaws-webfe-base-test, buaws-webfe-base-qa, buaws-webfe-base-prod)
- iam-landscape : this contains iam definitions per landscape elements
  (buaws-webfe-iam-syst, buaws-webfe-iam-devl, buaws-webfe-iam-test, buaws-webfe-iam-qa, buaws-webfe-iam-prod)
- 

The basic deployment workflow for non-production and www-syst will be:

1. Set up the account (right now this is a manual but well-defined process with local accounts (federation later).
2. Run the vpc stack with the web2cloud-nonprod settings.
3. Do the AWS side of the VPN connection (if not done by the vpc stack settings).
4. Run the base-landscape stack with the buaws-webfe-base-syst settings.
5. Run the iam-landscape stack with the buaws-webfe-iam-syst settings (by InfoSec).
6. Run the ecs-landscape stack with the buaws-webfe-ecs-syst settings.
7. Run the cloudfront-landscape stack with the buaws-webfe-cf-syst settings.


This top-level directory contains some simple shell scripts that are mainly wrappers around the standard 
CLI.  This was done for two reasons: 1) consistency of execution by multiple parties; and 2) as a learning
aid for understanding the AWS cli options for CloudFormation.

The current scripts are:

- create-stack.sh - creates a stack from scratch (for initial build).
- update-stack.sh - updates a stack immediately (mainly for initial development).
- changeset-create.sh - creates a changeset on what would change if one updated the template and settings.
- changeset-describe.sh - shows the contents of a changeset
- validate-template.sh - validates that a CF template is in the correct format.

Right we do not have any commands to delete a stack or delete/execute change sets.  This process can be done 
through the console.

Things to be aware of:
1. deleting IAM roles from iam-landscape will not delete them from the system, just from being tracked by CF
2. one needs to add the --capabilities CAPABILITY_IAM to the end of the create/update stack options.  For example,  ./update-stack.sh w2c-nonprod iam-landscape buaws-webfe-iam-syst --capabilities CAPABILITY_IAM

----
Old readme


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
