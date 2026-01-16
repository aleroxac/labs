# Lab1
Setting Up the Course Lab Environment

## Environment
- **Docker**: Used by kind to provision the Kubernetes cluster.
- **kind**: Used to create Kubernetes clusters.
- **kubectl**: Used to manage the Kubernetes cluster.
- **Helm**: Used for Kubernetes package management.
- **Siege**: A load testing tool.

## Setup - Linux Environment
### docker
``` shell
# 1. Install Docker:
curl -fsSL https://get.docker.com/ | sh
# 2. Enable Docker to start on boot:
sudo systemctl enable --now docker
# 3. Check that the Docker service is running:
sudo systemctl status docker
# 4. Add current user to Docker group:
sudo usermod -aG docker $USER
# 5. Refresh shell session (by exiting & logging in again).
# 6. Verify Docker installation:
```
### kubectl
``` shell
# 1. Download the binary:
curl -sSL -O "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# 2. Modify permissions:
chmod +x kubectl
# 3. Move to /usr/local/bin:
sudo mv kubectl /usr/local/bin
```
### helm
``` shell
# 1. Download Helm (if the link doesn't work, update the link with a version from GitHub releases):
curl -sSL -O https://get.helm.sh/helm-v3.19.0-linux-amd64.tar.gz
# 2. Extract the downloaded archive:
tar -zxf helm-v3.19.0-linux-amd64.tar.gz
# 3. Move the Helm binary to /usr/local/bin:
sudo mv linux-amd64/helm /usr/local/bin/helm
```
### siege
``` shell
# 1. Install the binary:
sudo apt-get install siege
```
### kind
``` shell
# 1. For AMD64 / x86_64:
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-amd64
# 2. For ARM64:
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-linux-arm64
# 3. Modify permissions:
chmod +x ./kind
# 4. Move the kind binary /usr/local/bin:
sudo mv ./kind /usr/local/bin/kind
# 5. Create cluster:
kind create cluster
# 6. Verify cluster:
kubectl get ns
```

## Setup - Metric Server Setup in Kubernetes
``` shell
# 1. Add Helm repository:
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
# 2. Install metrics server:
helm upgrade --install metrics-server metrics-server/metrics-server -n kube-system --set "args[0]"="--kubelet-insecure-tls"
# 3. Verify installation:
kubectl get pods -n kube-system -l=app.kubernetes.io/name=metrics-server
```
