# wercker-step-deploy-to-ecs
Step for deploying to ECS using Wercker.

Similar to the step `aws-ecs`, but it doesn't downscale the old service first and it takes a path to a JSON template for the task definition.

Currently, the step requires the AWS CLI to be installed in the 'box' it runs on.

# Parameters
| Name              | Description   |
| ----------------- | ------------- |
| aws_key           | The access key ID for an IAM user that can register tasks and update services for ECS. |
| aws_secret        | The secret for the above user. |
| aws_region        | The AWS region to operate in. |
| template_file     | Full path to the task definition JSON template file. |
| cluster           | The name of the ECS cluster. |
| service           | The name of the ECS service. |
| task              | The name (family) of the ECS task definition. |
