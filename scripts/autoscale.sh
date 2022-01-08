
# Choosing to use shared services cluster for the command sequence
DEMO_CLUSTER_NAME=$(yq e .workload-cluster-sm5.name $PARAMS_YAML)
WILD_CARD_FQDN=$(yq e .workload-cluster-sm5.ingress-fqdn $PARAMS_YAML)

tanzu cluster get $DEMO_CLUSTER_NAME
# see current number of workers

kubectl config use-context $DEMO_CLUSTER_NAME-admin@$DEMO_CLUSTER_NAME

# create new sample app from Kubernetes Up And Running (really could be any app)
kubectl create ns kuard

mkdir -p generated/$DEMO_CLUSTER_NAME/kuard
cp kuard/* generated/$DEMO_CLUSTER_NAME/kuard

export KUARD_FQDN=kuard.$(echo "$WILD_CARD_FQDN" | sed -e "s/^*.//")

yq e -i '.spec.rules[0].host = env(KUARD_FQDN)' generated/$DEMO_CLUSTER_NAME/kuard/ingress.yaml

kubectl apply -f generated/$DEMO_CLUSTER_NAME/kuard -n kuard

# open browser accessing sample app
open http://$KUARD_FQDN

# scale deployment
kubectl get nodes
# notice 2
kubectl scale deployment kuard --replicas 15 -n kuard
kubectl get po -n kuard
# notice pending pods
# switch context to MC
MANAGEMENT_CLUSTER_NAME=$(yq e .management-cluster.name $PARAMS_YAML)
kubectl config use-context $MANAGEMENT_CLUSTER_NAME-admin@$MANAGEMENT_CLUSTER_NAME
# check out the autoscaler pod logs in default namespace
kubectl get pods
# check out the machines.  A new one should be provisioning
kubectl get machines

# switch back to demo cluster
kubectl config use-context $DEMO_CLUSTER_NAME-admin@$DEMO_CLUSTER_NAME

# wait for additional nodes to be ready
kubectl get nodes

# when additional nodes are ready, pending pods should now be running
kubectl get pods -n kuard -o wide

# scale back down.  if you wait 10 minutes or so the added nodes should be removed.
kubectl scale deployment kuard --replicas 1 -n kuard
