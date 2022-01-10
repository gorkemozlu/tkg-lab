# TSM 

TSM UI
- Define Example Cluster Onboarding experience
- Choose one cluster and share more information about "edit configuration" which enables tsm namespaces.

## AcmeFitness App

Share Acme-fitness ap url

```
https://acme.example.com/
```
App is not responding with images because frondend app cannot access to backend.

Show frontend deployment yaml via octant so that app environment variables defines the backend services.

Show "node heatmap" at TSM UI so that services and worker nodes are easy to correlate with.

Create GNS at TSM UI:
 - Give a name
 - Do the service mapping
 - bypass if no avi integration is available.
 - deploy

```sh
kubectl config use-context essos-admin@essos

watch -n 1 kubectl get se -n acme-gns

```
Show GNS Topology at TSM UI.

```
locust --host=https://acme.example.com
#3 user
#10 spawn
```

Define actionable SLO at TSM UI.
```
P99 - 120ms
```
Enable autoscaler when it asks for.
```
autoscale metric: p99 - 60s
scale-up condition: 10ms
max instance count: 5
scale-down condition: 150ms - 60s
min instance count: 1
```
TSM UI -> GNS - Services  - frontend - performance

```
locust 
# 100 user
# 1000 spawn
```
