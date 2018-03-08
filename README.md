## Procedure for building the core infrastructure


## Building a Cloudfront virtual host

Once we create a CloudFront distribution we do not want to have to change it if at all posible. To make that 
possible we are building CloudFront distributions using a completely separate CloudFormation template from 
the other infrastructure.  This means that the CloudFront distributions will not be nested with another stack
nor import any values from another stack.  

Right now we are naming the CloudFormation stacks buaws-site-dashedhostname where dashedhostname is the hostname 
with all dots converted to dashes. For example `www-syst.bu.edu` becomes `www-syst-bu-edu` - this is because 
CloudFormation stacks are not allowed to have dots in their name.

This does mean that one needs to do the following process to get up a new CloudFront distribution/virtual host:

1. Import the InCommon SSL certificate into acm and record the ARN of the certificate.  This common name in the
   certificate becomes the Alias in the CloudFormation template.

2. Determine the WebACL value by looking at the WAFWebACL output of the buaws-webrouter-landscape-waf stack.

3. Determine the CloudFront log bucket by looking at the AccessLogBucket parameter of the 
   buaws-webrouter-landscape-waf stack.  Append `.s3.amazonaws.com` to the value to get the LogBucket parameter
   of the CloudFront stack.

4. Determine the RoutingOriginDNS entry by looking at the WebRouterDNS output from the buaws-webrouter-main-landscape
   stack.

5. Build the settings file for this virtual host in cloudfront/settings/stackname-parameters.json.

## How to calculate the memory and CPU size parameters

We are taking advantage of the target-based scaling for ECS to try and simplify this.  Also, we are scaling both ECS
and EC2 based on CPU values - actual CPU usage for ECS and reserved CPU for the EC2 instances.  Memory is not an 
issue with NGINX so we don't have to worry about that.  

Based on the results of load testing we might want to switch ECS to ALBRequestCountPerTarget.  That way we could scale
to keep ~500-600 connections to each NGINX container which is well under the 1024 maximum NGINX is currently set to.  
This should only be done if load testing shows that this version does not work properly.

ECS will not schedule docker containers if there is not enough memory to meet the memory limit.  This means that we 
need to calculate a value such that our minimum fits within the space allocated.

For example with our production load of 2 m4.large instances:

```
 m4.large x2 : cpu=2048*2 = 4048
               memory=8G*2 = 16G

 minimal state is 4 port 80 instances and 4 port 443 instances and the memory in those instances needs to fit in 
 less than 80% of the memory of the m4.large instances so auto-scaling will work properly.  In addition the values should be such that it can create 
 at least two more instance on each system.  Without that ECS will seem stuck because it wants to add more instances but there is 
 no room.  This problem does not seem to be logged anywhere - you just need to compare the desired and current values.

 Back to the calculations, let's plan for 8 instances on each instance in production with 4 being our normal state.
 100% / 6 = 16.66%.  If we set the memory to 10% then 8 instances will total 80% of the memory and 9 instances total 90% of memory.
 So we should change the 80% memory limit to 70% - this means that MemoryLimitNGINX should be 8096*0.10 = ~800 and CPU
 should be 2048* 0.10 = ~200.

 Our non-prod instances are running t2.small and we want to have 2 instances.  t2.small CPU is 1024 and memory is 2048.  If we do the same
 calculation then CPU should be 1024*0.15 = ~150 and memory should be 2048 *0.15 = ~300.

 ```

# older stuff 


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

https://github.com/pahud/ecs-cfn-refarch/blob/master/cloudformation/service.yml

