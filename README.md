# kube-backup
This is a simple script that generate an export of kubernetes cluster.
This script use git for version tracking.

## Requirements
This script depends on `git`, `kubectl` and `jq` (install them first).
You also must configure `kubectl` to connect to a cluster.

## Usage
This script has two optional parameters:
```
./kube-backup.sh
	-h | --help
	--commit-message="message" | -m="message"
	--directory="dump" | -d="dump"
	--kubectl-opts="" | -o=""
```
## Output
This script will output several yaml files by default in the "dump" directory
```
# tree
dump
├── default
│   ├── configmap
│   │   ├── haproxy.yaml
│   │   └── redis-cluster-config.yaml
│   ├── cronjob
│   ├── daemonset
│   ├── deployment
│   │   ├── cluster-manager.yaml
│   │   └── haproxy.yaml
│   ├── ingress
│   ├── job
│   ├── persistentvolumeclaim
│   │   └── build-claim.yaml
│   ├── pod
│   │   ├── haproxy-59fbc8c57b-mrplc.yaml
│   │   ├── redis-cluster-0.yaml
│   │   ├── redis-cluster-1.yaml
│   │   └── redis-cluster-2.yaml
│   ├── replicaset
│   │   ├── cluster-manager-6fff79bcd.yaml
│   │   └── haproxy-59fbc8c57b.yaml
│   ├── replicationcontroller
│   ├── rolebinding
│   │   └── website-rolebinding.yaml
│   ├── roles
│   │   └── website-role.yaml
│   ├── secret
│   │   ├── default-token-v8w72.yaml
│   │   ├── registry.yaml
│   │   └── website-token-v8wkx.yaml
│   ├── service
│   │   ├── haproxy.yaml
│   │   ├── kubernetes.yaml
│   │   └── redis-cluster.yaml
│   ├── statefulset
│   │   └── redis-cluster.yaml
[...]
├── kube-public
│   ├── configmap
│   │   └── cluster-info.yaml
[...]
├── kube-system
[...]
```
