# Lab2

## Learning the Basics of OpenTofu
### Initialize and Create a Local Resource
1. In the OpenTofu language, we declare resources representing infrastructure objects. In the following code
example, we are creating a resource, i.e., a local file named demo.txt, with the contents mentioned in the
block of the code. We define what resource we want to create and how the resource should look and feel using
the OpenTofu language. Using the editor of your choice, create the file main.tf with the contents below:
    ```
    resource "local_file" "hello_world" {
    filename = "${path.module}/demo.txt"
    content = <<-EOF
    Hello World!!!
    Welcome to the fascinating world of OpenTofu!
    EOF
    }
    ```

2. The OpenTofu CLI provides us with a few commands to make the OpenTofu code more convenient to work
with. The tofu fmt command reformats OpenTofu configuration files into a canonical format and style, saving
you the time and effort of making minor adjustments for readability and consistency. It works effectively as a
pre-commit hook in your version control system.
    ``` shell
    tofu fmt
    ```

3. Create a directory and move the OpenTofu code to the directory before we initialize a working directory:
    ``` shell
    mkdir demo && mv main.tf demo/ && cd demo
    ```

4. After writing the code, the first step is to initialize a new or existing OpenTofu working directory by creating
initial files, loading any remote state, downloading modules, and more. This is the first command you should
run for any new or existing OpenTofu configuration on each machine. It sets up all the necessary local data to
run OpenTofu, which is typically not committed to version control. You can safely run this command multiple
times. While subsequent runs may produce errors, this command will never delete your configuration or state.
    ``` shell
    tofu init
    ```

5. We can use an optional command tofu validate to validate the syntax and arguments of the
configuration files present in the directory:
    ``` shell
    tofu validate
    ```

6. Generate a speculative execution plan, showing what actions OpenTofu would take to apply the current
configuration. This command will not actually perform the planned actions:
    ``` shell
    tofu plan
    ```

7. We can create or update an existing infrastructure with the tofu apply command. Let us go ahead and
create the resource defined in our configuration file, i.e., a local file:
    ``` shell
    tofu apply
    ```

8. Verify the file was created in the local directory:
    ``` shell
    ls demo.txt && cat demo.txt
    ```

9. To create any infrastructure in OpenTofu, we need to define the resource in the OpenTofu language, initialize
a working directory, install the required plugins, generate a plan, and execute the plan by applying it. We can
also clean up and destroy the resource created with a simple destroy command. Let us clean up by
executing:
    ``` shell
    tofu destroy
    ```

10. Verify if the file has been cleaned up :
    ``` shell
    ls demo.txt
    ```
