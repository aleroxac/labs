# Lab2
Implementing HPA in Kubernetes

## Deploy Sample Application in Kubernetes
``` shell
# 2. Deploy the application:
kubectl apply -f webapp.yaml
# 3. Verify the deployment:
kubectl get deployments
# 4. Set up port forwarding to access the application.
nohup kubectl port-forward deploy/webapp 8080:80 &
# 5. Test the sample application by sending an HTTP request:
curl http://localhost:8080/
```

## Configure & Test HPA
``` shell
# 1. Create an HPA resource.
kubectl autoscale deployment webapp --min=2 --max=5 --cpu-percent=20
# 2. Check that HPA is correctly deployed:
kubectl get hpa
# 3. Generate load using Siege. (terminal 1)
siege -q -c 2 -t 1m http://localhost:8080
# 4. Monitor autoscaling. (terminal 2)
kubectl get hpa -w
# 5. HPA clean-up, delete HPA, and the deployment:
kubectl delete hpa webapp
kubectl delete deploy webapp
# 6. Kill the port-forward process
kill $(pgrep -f "kubectl port-forward") && rm nohup.out
```
