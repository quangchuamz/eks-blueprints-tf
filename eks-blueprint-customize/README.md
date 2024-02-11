# IAC

## I. Structure
2 kind of folders:
- **main folder**: which is used for main coding and reusing modules of terraform for example ***ecr*** module
- **modules folder**: which is used for coding module eg. ***ecr*** module folder
## II. File Descriptions
- **main.tf**: This is the primary file where the Terraform resources are defined. It usually contains the core logic of the Terraform code, including resource definitions, data source configurations, and module calls.

- **variables.tf**: This file declares variables that are used within the Terraform configuration files. It serves as a central place to define inputs that can be passed to the Terraform code, making the code more dynamic and reusable.

- **terraform.tfvars**: Contains the actual values for the variables defined in variables.tf. This file is typically used in local environments and can be customized for different setups. It's important not to commit sensitive values in this file to version control.

- **outputs.tf**: This file defines the outputs from the Terraform modules. Outputs are useful for extracting information about the resources created by Terraform, such as IP addresses, DNS names, and other critical data.

- **versions.tf**: Specifies the required Terraform version and provider versions. This is crucial for ensuring consistent behavior and compatibility of Terraform code across different environments.

- **provider.tf**: Contains the provider configuration for Terraform. Providers are plugins that Terraform uses to manage resources. Each provider offers a set of named resource types and data sources and translates the Terraform language into API calls to manage those resources.

**Best Practices**: 
Keep the main.tf file as clean and readable as possible, utilizing modules for complex configurations.
Use variables.tf to define necessary inputs with descriptions, making the code more modular.
Securely manage sensitive values, avoiding hardcoding them in terraform.tfvars.
Utilize outputs.tf to expose essential information about the infrastructure.
Ensure version compatibility by correctly setting versions.tf.
Define and configure providers appropriately in provider.tf.

## Modules
### ecr
1. Define the Variable
First, define a variable in your Terraform configuration to hold the list of repository names. Create a file called variables.tf and add the following:
```terraform
variable "repository_names" {
  description = "A list of ECR repository names"
  type        = list(string)
}

```
2. Use the Variable in a Resource with for_each
   In your main Terraform configuration file (e.g., main.tf), use the aws_ecr_repository resource with the for_each construct to create a repository for each name in the list.
```terraform
resource "aws_ecr_repository" "ecr_repo" {
  for_each = toset(var.repository_names)

  name                 = each.value
  image_tag_mutability = "MUTABLE"
  // other configuration ...
}

```
3. Provide the Variable Values
   You can provide the values for your variable in a few different ways, such as through a terraform.tfvars file, environment variables, or command line flags. If you're using a terraform.tfvars file, it would look something like this:
```terraform
repository_names = ["repo1", "repo2", "repo3"]

```

## Runbook
Go to the global variables to put desired value for ecr at this file [terrafrom.tfvars](tech-team/terraform.tfvars)
```terraform
repository_names = ["repo1", "repo2", "repo3", "repo4"] #your repos
aws_region = "ap-southeast-1" #your region
aws_profile = "isg_hdb" #your aws profile with access key

```
Initialize and Apply Your Configuration
   Run the following commands in your terminal:
```bash
terraform init #to initialize the Terraform configuration.
terraform plan #to see the execution plan.
terraform apply #to apply the changes and create the repositories.
```




