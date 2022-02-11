#!/bin/bash

kubectl --kubeconfig /etc/kubernetes/admin.conf get pods `kubectl --kubeconfig /etc/kubernetes/admin.conf  get pods -A | grep etc | awk '{print $2}'` -n kube-system  -o=jsonpath='{.spec.containers[0].command}' | jq

#[
#  "etcd",
#  "--advertise-client-urls=https://10.213.217.134:2379",
#  "--cert-file=/etc/kubernetes/pki/etcd/server.crt",
#  "--client-cert-auth=true",
#  "--data-dir=/var/lib/etcd",
#  "--initial-advertise-peer-urls=https://10.213.217.134:2380",
#  "--initial-cluster=tkgs-cluster-2-control-plane-mw5wb=https://10.213.217.134:2380,tkgs-cluster-2-control-plane-wtx7g=https://10.213.217.133:2380",
#  "--initial-cluster-state=existing",
#  "--key-file=/etc/kubernetes/pki/etcd/server.key",
#  "--listen-client-urls=https://127.0.0.1:2379,https://10.213.217.134:2379",
#  "--listen-metrics-urls=http://127.0.0.1:2381",
#  "--listen-peer-urls=https://10.213.217.134:2380",
#  "--name=tkgs-cluster-2-control-plane-mw5wb",
#  "--peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt",
#  "--peer-client-cert-auth=true",
#  "--peer-key-file=/etc/kubernetes/pki/etcd/peer.key",
#  "--peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt",
#  "--snapshot-count=10000",
#  "--trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt"
#]

#ssh into master node
find / -type f -name "*etcdctl*" -print

/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/21/fs/usr/local/bin/etcdctl snapshot save /tmp/etcdBackup1.db \
  --endpoints=https://10.213.217.134:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/21/fs/usr/local/bin/etcdctl --write-out=table snapshot status /tmp/etcdBackup1.db
/usr/bin/scp etcdBackup1.db ubuntu@10.213.216.4:/tmp/etcd1.db

/var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/21/fs/usr/local/bin/etcdctl \
--endpoints=https://10.213.217.134:2379 \
--cacert=/etc/kubernetes/pki/etcd/ca.crt \
--name=tkgs-cluster-2-control-plane-mw5wb \
--cert=/etc/kubernetes/pki/etcd/server.crt \
--key=/etc/kubernetes/pki/etcd/server.key \
--data-dir /var/lib/etcd-restore \
--initial-cluster=tkgs-cluster-2-control-plane-mw5wb=https://10.213.217.134:2380,tkgs-cluster-2-control-plane-wtx7g=https://10.213.217.133:2380 \
--initial-advertise-peer-urls=https://10.213.217.134:2380 \
snapshot restore /tmp/etcdBackup1.db


