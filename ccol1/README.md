# [CCO-L1 - Certified Calico Operator: Level 1](https://academy.tigera.io/course/certified-calico-operator-level-1/)

## [Lab Setup on Archlinux](https://snapcraft.io/docs/installing-snap-on-arch-linux)
``` shell
# --- snap installation
cd /tmp
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si
sudo systemctl enable --now snapd.socket

# --- multipass installation
sudo snap install multipass

# --- validation the lab orchestrator installation
multipass launch -n test1
multipass info test1
# if needed, run: multipass start --all
multipass shell test1
multipass delete test1
multipass purge
```

## Creating the Lab Environment
``` shell
# --- quick start
curl https://raw.githubusercontent.com/tigera/ccol1/main/control-init.yaml | multipass launch -n control -m 2048M 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/node1-init.yaml | multipass launch -n node1 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/node2-init.yaml | multipass launch -n node2 20.04 --cloud-init -
curl https://raw.githubusercontent.com/tigera/ccol1/main/host1-init.yaml | multipass launch -n host1 20.04 --cloud-init -

# --- starting the instances
# if needed, run: multipass start --all
multipass list

# --- validating the environment
echo "kubectl get node -A"  | multipass shell host1
```

## Installing Calico
``` shell
## --- installing the operator
multipass shell host1
    kubectl create -f https://docs.projectcalico.org/archive/v3.21/manifests/tigera-operator.yaml
    kubectl wait --for=condition=available deployment tigera-operator -n tigera-operator
    kubectl get pods -n tigera-operator

# --- installing calico
cat <<EOF | kubectl apply -f -
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    containerIPForwarding: Enabled
    ipPools:
    - cidr: 198.19.16.0/21
      natOutgoing: Enabled
      encapsulation: None
EOF

## --- validating the calico installation
kubectl get tigerastatus/calico
kubectl get pods -A

## --- reviewing calico pods
kubectl get pods -n calico-system

## --- reviewing node health
kubectl get nodes -A
```


## Installing the Sample Application
``` shell
multipass shell host1

## --- install the sample application
kubectl apply -f https://raw.githubusercontent.com/tigera/ccol1/main/yaobank.yaml

## --- check the deployment status
kubectl wait --for=condition=available deployment/database -n yaobank
kubectl wait --for=condition=available deployment/summary -n yaobank
kubectl wait --for=condition=available deployment/customer -n yaobank

## --- access the sample application web gui
curl -sv http://198.19.0.1:30180
```

## Stopping and Resuming your Lab
``` shell
## --- stop
multipass stop --all

## --- list
multipass list

## --- start
multipass start control
multipass start node1
multipass start node2
multipass start host1

## --- tear down
multipass delete --all
multipass purge
```


## Network Policy Fundamentals
``` shell
# --- simulating a compromise
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -it $CUSTOMER_POD -n yaobank -c customer -- /bin/bash -c "curl http://database:2379/v2/keys?recursive=true | python -m json.tool"

# --- deploy the k8s network policy
cat <<EOF | kubectl apply -f -
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: database-policy
  namespace: yaobank
spec:
  podSelector:
    matchLabels:
      app: database
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: summary
    ports:
      - protocol: TCP
        port: 2379
  egress:
    - to: []
EOF

# -- try to attack again
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -it $CUSTOMER_POD -n yaobank -c customer -- /bin/bash -c "curl --connect-timeout 3 http://database:2379/v2/keys?recursive=true"

# --- default-deny network policy
cat <<EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-app-policy
spec:
  namespaceSelector: has(projectcalico.org/name) && projectcalico.org/name not in {"kube-system", "calico-system", "calico-apiserver"}
  types:
  - Ingress
  - Egress
EOF

# --- verify default deny is in place
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash -c "dig www.google.com"

# --- allow dns
cat <<EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-app-policy
spec:
  namespaceSelector: has(projectcalico.org/name) && projectcalico.org/name not in {"kube-system", "calico-system"}
  types:
  - Ingress
  - Egress
  egress:
    - action: Allow
      protocol: UDP
      destination:
        selector: k8s-app == "kube-dns"
        ports:
          - 53
EOF

# --- test the dns resolution again
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash -c "dig www.google.com"

# --- verify we cannot access the Frontend
curl --connect-timeout 3 198.19.0.1:30180

# --- Create policy for the remaining pods
cat <<EOF | kubectl apply -f - 
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: customer-policy
  namespace: yaobank
spec:
  podSelector:
    matchLabels:
      app: customer
  ingress:
    - ports:
      - protocol: TCP
        port: 80
  egress:
    - to: []
---
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: summary-policy
  namespace: yaobank
spec:
  podSelector:
    matchLabels:
      app: summary
  ingress:
    - from:
      - podSelector:
          matchLabels:
            app: customer
      ports:
      - protocol: TCP
        port: 80
  egress:
    - to:
      - podSelector:
          matchLabels:
            app: database
      ports:
      - protocol: TCP
        port: 2379
EOF

# --- verify everything is now working
curl 198.19.0.1:30180
```

## Managing Trust Across Teams
``` shell
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -it $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
    ping -c 3 8.8.8.8
    curl --connect-timeout 3 -I www.google.com
    exit

## --- blocking the egress
cat <<EOF | calicoctl apply -f -
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: egress-lockdown
spec:
  order: 600
  namespaceSelector: has(projectcalico.org/name) && projectcalico.org/name not in {"kube-system", "calico-system"}
  serviceAccountSelector: internet-egress not in {"allowed"}
  types:
  - Egress
  egress:
    - action: Deny
      destination:
        notNets:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
          - 198.18.0.0/15
EOF

kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
    ping -c 3 8.8.8.8
    curl --connect-timeout 3 -I www.google.com
    exit

kubectl label serviceaccount -n yaobank customer internet-egress=allowed

kubectl exec -ti $CUSTOMER_POD -n yaobank -c customer -- /bin/bash
    ping -c 3 8.8.8.8
    curl --connect-timeout 3 -I www.google.com
    exit
```

## Network Policy for Hosts and NodePorts
``` shell
## --- Observe that Kubernetes nodes are not yet secured (you were able access the FTP server, which is not a good security posture.)
nc -zv -w 3 198.19.0.1 21

## --- Create Network Policy for Nodes
cat <<EOF | calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-node-policy
spec:
  selector: has(kubernetes.io/hostname)
  ingress:
  - action: Allow
    protocol: TCP
    source:
      nets:
      - 127.0.0.1/32
  - action: Allow
    protocol: UDP
    source:
      nets:
      - 127.0.0.1/32
EOF

# --- Create Host Endpoints
calicoctl get heps
calicoctl patch kubecontrollersconfiguration default --patch='{"spec": {"controllers": {"node": {"hostEndpoint": {"autoCreate": "Enabled"}}}}}'
calicoctl get heps

# --- Try to access FTP again
nc -zv -w 3 198.19.0.1 21

# --- Lock down node port access
cat <<EOF | calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: nodeport-policy
spec:
  order: 100
  selector: has(kubernetes.io/hostname)
  applyOnForward: true
  preDNAT: true
  ingress:
  - action: Deny
    protocol: TCP
    destination:
      ports: ["30000:32767"]
  - action: Deny
    protocol: UDP
    destination:
      ports: ["30000:32767"]
EOF

# --- Verify you cannot access yaobank frontend
curl --connect-timeout 3 198.19.0.1:30180

# --- Selectively allow access to customer front end
cat <<EOF | calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: nodeport-policy
spec:
  order: 100
  selector: has(kubernetes.io/hostname)
  applyOnForward: true
  preDNAT: true
  ingress:
  - action: Allow
    protocol: TCP
    destination:
      ports: [30180]
    source:
      nets:
      - 198.19.15.254/32
  - action: Deny
    protocol: TCP
    destination:
      ports: ["30000:32767"]
  - action: Deny
    protocol: UDP
    destination:
      ports: ["30000:32767"]
EOF

# --- Verify again
curl --connect-timeout 3 198.19.0.1:30180
```

### What about control plane traffic?
    You might be wondering why the above network policy does not break the Kubernetes and Calico control planes. After all, they need to make non-local connections in order to function correctly. 

    The answer is that Calico has a configurable list of “failsafe” ports which take precedence over any policy. These failsafe ports ensure the connections required for the host networked Kubernetes and Calico control planes processes to function are always allowed (assuming your failsafe ports are correctly configured). This means you don’t have to worry about defining policy rules for these. The default failsafe ports also allow SSH traffic so you can always log into your nodes.

    If it wasn’t for these failsafe rules then the above policy would actually stop the Calico and Kubernetes control planes from working, and to fix the situation you would need to fix the network policy and then reboot each node so it can regain access to the control plane. So we always recommend ensuring you have the correct failsafe ports configured before you start applying network policies to host endpoints!


## How pods see the network
``` shell
multipass shell host1
kubectl get pods -n yaobank -l app=customer -o wide

## --- Exec into the pod
CUSTOMER_POD=$(kubectl get pods -n yaobank -l app=customer -o name)
kubectl exec -ti -n yaobank $CUSTOMER_POD -- /bin/bash
    ip addr
    ip -c link show up
    ip route
    exit

kubectl get pods -n yaobank -l app=customer -o wide
ssh node1
    ip -c link show up
    exit

kubectl get pods -n yaobank -l app=customer -o wide
ssh node1
    ip route
```


## Encrypting data in transit
``` shell
multipass shell host1


# --- enabling encryption and inspecting WireGuard status
calicoctl patch felixconfiguration default --type='merge' -p '{"spec":{"wireguardEnabled":true}}'
calicoctl get node node1 -o yaml
ssh node1
    ip addr | grep wireguard
    exit

# --- disabling encryption and inspecting WireGuard status
calicoctl patch felixconfiguration default --type='merge' -p '{"spec":{"wireguardEnabled":false}}'
calicoctl get node node1 -o yaml
```


## IP Pools and BGP Peering
``` shell
multipass shell host1

# --- k8s configuration
kubectl cluster-info dump | grep -m 2 -E "service-cidr|cluster-cidr"

# --- calico configuration
calicoctl get ippools


# 198.19.16.0/20 - Cluster Pod CIDR
# 198.19.16.0/21- Default IP Pool CIDR
# 198.19.32.0/20 - Service CIDR


# Create externally routable IP Pool
cat <<EOF | calicoctl apply -f - 
---
apiVersion: projectcalico.org/v3
kind: IPPool
metadata:
  name: external-pool
spec:
  cidr: 198.19.24.0/21
  blockSize: 29
  ipipMode: Never
  natOutgoing: true
  nodeSelector: "!all()"
EOF
calicoctl get ippools 


# 198.19.16.0/20 - Cluster Pod CIDR
# 198.19.16.0/21 - Default IP Pool CIDR
# 198.19.24.0/21 - External Pool CIDR
# 198.19.32.0/20 - Service CIDR

# --- Examine BGP peering status
ssh node1
    sudo calicoctl node status
    exit

# --- Add a BGP Peer
cat <<EOF | calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: BGPPeer
metadata:
  name: bgppeer-global-host1
spec:
  peerIP: 198.19.15.254
  asNumber: 64512
EOF
ssh node1
    sudo calicoctl node status
    exit

# --- Configure a Namespace to use External Routable IP Addresses

## --- Create the namespace
cat <<EOF| kubectl apply -f - 
---
apiVersion: v1
kind: Namespace
metadata:
  annotations:
    cni.projectcalico.org/ipv4pools: '["external-pool"]'
  name: external-ns
EOF

## --- Deploy an NGINX pod
kubectl apply -f https://raw.githubusercontent.com/tigera/ccol1/main/nginx.yaml
curl https://raw.githubusercontent.com/tigera/ccol1/main/nginx.yaml | sed 's/node1/node2/g' | kubectl apply -f-

## --- Access the NGINX pod from outside the cluster
kubectl get pods -n external-ns -o wide
curl 198.19.25.96
calicoctl ipam show
```


## Understanding Kube-proxy
``` shell
# --- examine k8s services
multipass shell host1
kubectl get svc -n yaobank
kubectl get endpoints -n yaobank
kubectl get pods -n yaobank -o wide

# --- Kube-Proxy Cluster IP Implementation
kubectl get endpoints -n yaobank summary

ssh node1
## --- Examine the KUBE-SERVICE chain
    sudo iptables -v --numeric --table nat --list KUBE-SERVICES
## --- KUBE-SERVICES -> KUBE-SVC-XXXXXXXXXXXXXXXX
    sudo iptables -v --numeric --table nat --list KUBE-SERVICES | grep -E summary
## --- KUBE-SVC-XXXXXXXXXXXXXXXX -> KUBE-SEP-XXXXXXXXXXXXXXXX
    sudo iptables -v --numeric --table nat --list KUBE-SVC-OIQIZJVJK6E34BR4
## --- KUBE-SEP-XXXXXXXXXXXXXXXX -> summary pod
    sudo iptables -v --numeric --table nat --list KUBE-SEP-JB2CV3IQT3I5TZRW
    exit

# --- Kube-Proxy NodePort Implementation
## --- get service endpoints
kubectl get endpoints -n yaobank customer

## --- KUBE-SERVICES -> KUBE-NODEPORTS
ssh node1
    sudo iptables -v --numeric --table nat --list KUBE-SERVICES | grep KUBE-NODEPORTS
## -- KUBE-NODEPORTS -> KUBE-SVC-XXXXXXXXXXXXXXXX
    sudo iptables -v --numeric --table nat --list KUBE-NODEPORTS
## -- KUBE-SVC-XXXXXXXXXXXXXXXX -> KUBE-SEP-XXXXXXXXXXXXXXXX
    sudo iptables -v --numeric --table nat --list KUBE-SVC-PX5FENG4GZJTCELT
## - KUBE-SEP-XXXXXXXXXXXXXXXX -> customer endpoint
    sudo iptables -v --numeric --table nat --list KUBE-SEP-UBXKSM3V2OSEF4IL
    exit
```

## Understanding Calico Native Service Handling
``` shell
# --- NodePort without source IP preservation
multipass shell host1
kubectl logs -n yaobank -l app=customer --follow
curl 198.19.0.1:30180

# --- Enable Calico eBPF
## --- Configure Calico to connect directly to the API server
cat <<EOF | kubectl apply -f -
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "198.19.0.1"
  KUBERNETES_SERVICE_PORT: "6443"
EOF
kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator
watch kubectl get pods -n calico-system

## --- Disable kube-proxy
calicoctl patch felixconfiguration default --patch='{"spec": {"bpfKubeProxyIptablesCleanupEnabled": false}}'

## --- Switch on eBPF mode
kubectl patch installation.operator.tigera.io default --type merge -p '{"spec":{"calicoNetwork":{"linuxDataplane":"BPF", "hostPorts":null}}}'

kubectl delete pod -n yaobank -l app=customer
kubectl delete pod -n yaobank -l app=summary

# --- Source IP preservation
curl 198.19.0.1:30180
kubectl logs -n yaobank -l app=customer --follow

# --- Snoop traffic without DSR
ssh control
    sudo tcpdump -nvi any 'tcp port 30180'

# from the host1 instance
    curl 198.19.0.1:30180 
    calicoctl patch felixconfiguration default --patch='{"spec": {"bpfExternalServiceMode": "DSR"}}'
    curl 198.19.0.1:30180
```


## Advertising Services
``` shell
multipass shell host1

# --- Examine routes
ip route

# --- Update Calico BGP configuration
cat <<EOF | calicoctl apply -f -
---
apiVersion: projectcalico.org/v3
kind: BGPConfiguration
metadata:
  name: default
spec:
  serviceClusterIPs:
  - cidr: "198.19.32.0/20"
EOF
calicoctl get bgpconfig default -o yaml
ip route

# --- Verify we can access cluster IPs
kubectl get svc -n yaobank customer
curl 198.19.34.92

# --- Advertise External IPs
## --- Examine the existing services
kubectl get svc -n yaobank

## --- Update BGP configuration
calicoctl patch BGPConfig default --patch \
   '{"spec": {"serviceExternalIPs": [{"cidr": "198.19.48.0/20"}]}}'
ip route

# --- Assign the service external IP
kubectl patch svc -n yaobank customer -p  '{"spec": {"externalIPs": ["198.19.48.10"]}}'
kubectl get svc -n yaobank
### --- Verify we can access the service's external IP
curl 198.19.48.10
```
