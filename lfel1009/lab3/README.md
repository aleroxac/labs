# Lab3

## Creating a Virtual Machine using OpenTofu
1. Create a separate directory for storing your OpenTofu code:
    ``` shell
    mkdir newproject && cd newproject
    ```

2. Using the editor of your choice, create the file main.tf with the content below:
    ```
    provider "aws" {
        region = "us-east-1"
            access_key = "xxxxxxxxxxxxxxxxxxxxxxx"
            secret_key = "xxxxxxxxxxxxxxxxxxxxxxxx"
    }
    resource "aws_instance" "firstvm" {
        ami = "ami-053b0d53c279acc90"
        instance_type = "t2.micro"
        subnet_id = "subnet-xxxxxxxxxx"
    }
    ```
    Note: Please replace the “access_key”, “secret_key” and “subnet_id” with your credentials and subnet
    ID.

3. The OpenTofu CLI provides us with a few commands to make the OpenTofu code more convenient to work
with. The tofu fmt command reformats OpenTofu configuration files into a canonical format and style, saving
you the time and effort of making minor adjustments for readability and consistency.
    ``` shell
    tofu fmt
    ```

4. Initialize the working directory by executing the following command:
    ``` shell
    tofu init
    ```

5. Generate a speculative execution plan, showing what actions OpenTofu would take to apply the current
configuration. This command will not actually perform the planned actions:
    ``` shell
    tofu plan
    ```

6. We can create the virtual machine with the tofu apply command. Let us go ahead and create the
resource defined in our configuration file, i.e., an AWS EC2 instance:
    ``` shell
    tofu apply
    ```

7. Congratulations: you have created your first EC2 instance using OpenTofu. Login into your AWS console
and verify the machine has been created.

8. After verification, let us clean up and destroy the resource created.
    ``` shell
    tofu destroy
    ```
