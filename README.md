# ECR Repository

This tiny module allows for terraforming a list of ECR repositories with cross account pull capabilities. You can use the module as such:

## Example Default Usage

``` hcl
module "ecr_repo" {
  source            = "github.com/7factor/terraform-ecr"

  repository_list   = ["repo-a", "repo-b"]
  account_list		= [1234567890, 0987654321]
}
```

This module also allows cross account pull capabilities to be used by AWS Lambda. You can set the `allow_lambda_pull` flag to `true` to allow the *current* accounts Lambda service to pull from accounts listed in `account_list`'s ECR. 

**Note:** This feature will only allow cross account pull access to accounts that are listed in in the `account_list` parameter.  

## Example Lambda Usage
``` hcl
module "ecr_repo" {
  source            = "github.com/7factor/terraform-ecr"

  repository_list   = ["repo-a", "repo-b"]
  account_list		= [1234567890, 0987654321]

  allow_lambda_pull = true
}
```

Instead of defaulting to a single block and forcing users to create as many blocks as they have applications we assume you want to create a list of repositories. This is purely for convenience, and it does reduce the control you have over each individual repo (like lifecycle policies etcetera). We can certainly tackle this later if there is a good reason to support more complex configuration blobs.

This module uses magic to find out the *current* account it's running in which is where all the repositories will be created. We assume that you want to store your artifacts near your CI/CD system and wish to provide cross account access to those. This makes it faster and cheaper because the images don't have far to go.
