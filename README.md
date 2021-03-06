# workshop-aws-secrets-manager

## Pre-reqs
Installed:
```
awscli
ansible
terraform
```
## Configuration
Configure your AWS credentials for terraform:
```
$ export AWS_ACCESS_KEY_ID="anaccesskey"
$ export AWS_SECRET_ACCESS_KEY="asecretkey"
$ export AWS_DEFAULT_REGION="eu-west-1"
```


## Creating a secret manually and retrieving it with ansible.
For the first task we will create a secret manually through AWSCLI and test the retrieval and usage in ansible

1 - create secret in AWS SM -

`aws secretsmanager create-secret --name TestSecret --secret-string HelloWorld`

2 - You can test if everything was created successfully by running

`aws secretsmanager get-secret-value --secret-id TestSecret`

You should get the contents of the secret in your CLI.

3 - Now we can test the retrieval through the use of ansible by running

`ansible-galaxy collection install amazon.aws`

`ansible-playbook ansible/echo.yml -e "awssecretname=TestSecret"`

If everything went correctly, you should have the contents of the secret in the execution output.
Now for cleanup - 

`aws secretsmanager delete-secret --secret-id TestSecret --force-delete-without-recovery`

## Using terraform to set secrets
We can use terraform to set the secrets, in practice - this is something that wouldn't be used on its own, but rather in conjunction with other modules.
The configuration is fairly basic, and can be viewed under `./terraform/01_basic_secret/main.tf`
To execute it:

`cd terraform/01_basic_secret/main.tf`

`terraform init`

`terraform plan`

`terraform apply`

You should have output with the ARN's of the created resources.
To test it, we can use awscli again

`aws secretsmanager get-secret-value --secret-id testvariable`

and

`aws secretsmanager get-secret-value --secret-id testvariable_generated`

We can see it as an example of both hardcoded secrets and autogenerated ones.
Once its all done, we can clean up by running

`terraform destroy`


## Using terraform to create an RDS instance where the password is saved directly to AWS SM
This module already creates a basic environment and configures an RDS instance in a VPC, using a randomly generated password, that doesn't get stored
(outside of the statefile) locally, and instead gets automatically stored in the AWS secrets manager, allowing other applications to access it programmatically.

`cd terraform/02_rds_with_SM`

`terraform init`

`terraform plan`

`terraform apply`

This will take around 8 minutes, since it waits for the actual RDS instance to be up and available before considering it complete.
For cleanup we can run

`terraform destroy`

again.

## Creating a lambda function that uses SM to access the RDS database
Here we will create a small basic lambda function with an api gateway entrypoint that retrieves data from the secret manager

`cd terraform/03_lambda`

`terraform init`

`terraform plan`

`terraform apply`

As the process completes, you will get the url for the api gateway in the output.
You can open and test it.

For cleanup, can run terraform destroy again.


___
### Notes

* Don't use local backend for production usage, instead use something like S3 for storage and DynamoDB for statelocking

