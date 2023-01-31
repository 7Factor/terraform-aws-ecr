# ECR Repository

This tiny module allows for terraforming a list of ECR repositories with cross account pull capabilities. You can use the module as such:

## Prerequisites
First, you need a decent understanding of how to use Terraform. [Hit the docs](https://www.terraform.io/intro/index.html) for that. Then, you should familiarize yourself with ECR concepts, especially if you've never worked with a clustering solution before. Once you're good, import this module and pass the appropriate variables. Then, plan your run and deploy.

## Example Usages

### Default Usage

``` hcl
module "ecr_repo" {
  source  = "7factor/ecr/aws"
  version = "~> 1"

  repository_list   = ["repo-a", "repo-b"]
  account_list		= [1234567890, 0987654321]
}
```

This module also allows cross account pull capabilities to be used by AWS Lambda. You can set the `allow_lambda_pull` flag to `true` to allow the *current* accounts Lambda service to pull from accounts listed in `account_list`'s ECR. 

**Note:** This feature will only allow cross account pull access to accounts that are listed in in the `account_list` parameter.  

### Lambda Usage
``` hcl
module "ecr_repo" {
  source  = "7factor/ecr/aws"
  version = "~> 1"

  repository_list   = ["repo-a", "repo-b"]
  account_list		= [1234567890, 0987654321]

  allow_lambda_pull = true
}
```

Instead of defaulting to a single block and forcing users to create as many blocks as they have applications we assume you want to create a list of repositories. This is purely for convenience, and it does reduce the control you have over each individual repo (like lifecycle policies etcetera). We can certainly tackle this later if there is a good reason to support more complex configuration blobs.

This module uses magic to find out the *current* account it's running in which is where all the repositories will be created. We assume that you want to store your artifacts near your CI/CD system and wish to provide cross account access to those. This makes it faster and cheaper because the images don't have far to go.

## Migrating from github.com/7factor/terraform-ecr
This is the new home of the terraform-ecr module. It was copied here so that changes wouldn't break services relying on the old repo. Going forward, you should endeavour to use this version of the module. More specifically, use the module from the [Terraform registry](https://registry.terraform.io/modules/7Factor/ecr/aws/latest). This way, you can select a range of versions to use in your service which allows us to make potentially breaking changes to the module without breaking your service.

## Migration instructions
You need to change the module source from the GitHub url to 7Factor/ecr/aws. This will pull the module from the Terraform registry. You should also add a version to the module block. See the [example](#example-usage) above for what this looks like together.

Major version 1 is intended to maintain backwards compatibility with the old module source. To use the new module source and maintain compatibility, set your version to "~> 1". This means you will receive any updates that are backwards compatible with the old module.
