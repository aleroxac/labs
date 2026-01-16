# Lab3
Installing KEDA and Setting Up Cron Scaler

## Install KEDA Using Helm Chart
``` shell
# 1. Install KEDA using Helm.
helm repo add kedacore https://kedacore.github.io/charts
helm repo update
helm upgrade -i keda kedacore/keda --namespace keda --create-namespace
# 2. Verify KEDA pods are running in the cluster, using the command below:
kubectl get deployment -n keda
# 3. Create a deployment, using the command below:
kubectl create deploy myapp --image nginx --replicas=2
# 4. Verify the deployment:
kubectl get deployments
# 5. Create the ScaledObject using the below command:
kubectl apply -f cron.yaml
# 6. Verify the ScaledObject:
kubectl get scaledobject.keda.sh
# 7. The ScaledObject will scale the application pods to the desired number of replicas when the schedule triggers.
watch kubectl get all
```
