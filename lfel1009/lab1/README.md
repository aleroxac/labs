# Lab1

## Linux Environment Setup
``` shell
# 1. Before we download the installation script, let's update the system and install some necessary tools.
# Note: On most operating systems, these tools might already be installed.
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# 2. Download the installer script using the following command:
curl -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh

# 3. Grant the script execute permission and verify:
chmod +x install-opentofu.sh && ls -l install-opentofu.sh

# 4. If you're familiar with shell scripting, feel free to review the script; if not, there's no need to worry - simply
# proceed to step 5:
less install-opentofu.sh

# 5. Execute the installer script to install OpenTofu. The script requires a mandatory argument known as the
# --install-method. The value will differ depending on your operating system and package manager. We are
# installing it on the Ubuntu system and will use snap (snapcraft) as the installation method of choice.
sudo ./install-opentofu.sh --install-method snap

# 6. The command line interface to OpenTofu is the tofu command. Verify the installation by executing the help:
tofu -h

# 7. OpenTofu provides tab-completion support for all command names, as well as some command arguments.
# To set up auto-completion, execute the following command:
tofu -install-autocomplete

# Note: After installation, you need to restart your shell or reload its profile script to activate completion.
```
