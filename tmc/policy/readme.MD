# Policies

## Image Registry

```sh
kubectl config use-context highgarden-admin@highgarden

watch -n 1 kubectl get pods -n gorkemo-policy-playground
kubectl create deployment nginx --image=nginx:latest -n gorkemo-policy-playground

kubectl delete deployment nginx -n gorkemo-policy-playground
```


```
https://tanzuemea.tmc.cloud.vmware.com/policies/assignments/image-policy/hierarchy/workspaces/resource/ws:01FPDFFT0WGJM6YP7WK5B43GE6
```
add "block-latest" image policy.

```sh
stern -n vmware-system-tmc policy-sync

kubectl get policydefinitions

kubectl create deployment nginx --image=nginx:latest -n gorkemo-policy-playground

kubectl delete deployment nginx -n gorkemo-policy-playground

#kubectl expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer -n gorkemo-policy-playground
```
## Security

add "baseline-policy".
Include only specific namespaces

```sh
tmc.cloud.vmware.com/workspace: gorkemo-policy-playground-ws

kubectl config use-context highgarden-admin@highgarden

watch -n 1 kubectl get pods -n gorkemo-policy-playground

stern -n vmware-system-tmc policy-sync

kubectl get policydefinitions

kubectl apply -f - <<EOT
apiVersion: v1
kind: Pod
metadata:
  name: nginx-privileged
  namespace: gorkemo-policy-playground
  labels:
    app: nginx-privileged
spec:
  containers:
  - name: nginx
    image: nginx
    securityContext:
      privileged: true #false
EOT

kubectl delete pod nginx-privileged -n gorkemo-policy-playground
```






















kubectl get clusterpolicies