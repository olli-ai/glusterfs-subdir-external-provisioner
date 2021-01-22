# Kubernetes GlusterFS-Client Provisioner

GlusterFS subdir external provisioner is an automatic provisioner that use your _existing and already configured_ GlusterFS volume to support dynamic provisioning of Kubernetes Persistent Volumes via Persistent Volume Claims. Persistent volumes are provisioned as subdirectories named `${namespace}-${pvcName}-${pvName}`.

To note again, you must _already_ have an GlusterFS cluster with a volume.

Unlike [Heketi](https://github.com/heketi/heketi), this prosvisionner will use an existing GlusterFS volume, which allows you to manage it however you want, including adding new servers in the GlusterFS volume at any time.

This is a fork from [NFS subdir external provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) adapted to GlusterFS.

### Deploy with Helm

Currenlty, kubernetes endpoints anly support IP addresses. The support for hostnames is [discussed](https://github.com/kubernetes/kubernetes/issues/4447) be doesn't seem to be planned.

```bash
helm repository add olli-ai https://olli-ai.github.io/helm-charts/
helm install glusterfs-client olli-ai/glusterfs-client-provisioner \
    --namespace default \
    --set glusterfs.server='{x.x.x.x,y.y.y.y}' \
    --set glusterfs.volume=volume
```

You may prefer to have you own Endpoints, that you can update when changing the GlusterFS cluster.

```bash
echo <<<EOF | apply --namespace default -f -
kind: Endpoints
apiVersion: v1
metadata:
  name: my-endpoints
subsets:
- addresses:
  - ip: x.x.x.x
  ports:
  - port: 1 # the port has no impact
EOF
helm repository add olli-ai https://olli-ai.github.io/helm-charts/
helm install glusterfs-client olli-ai/glusterfs-client-provisioner \
    --namespace default \
    --set endpoints.create=false \
    --set endpoints.name=my-endpoints \
    --set glusterfs.volume=volume
```

| Parameter                           | Description                                                 | Default                               |
| ----------------------------------- | ----------------------------------------------------------- | ------------------------------------- |
| `replicaCount`                      | Number of provisioner instances to deployed                 | `1`                                   |
| `strategyType`                      | Specifies the strategy used to replace old Pods by new ones | `Recreate`                            |
| `image.repository`                  | Provisioner image                                           | `olliai/glusterfs-client-provisioner` |
| `image.tag`                         | Version of provisioner image                                | Chart's version                       |
| `image.pullPolicy`                  | Image pull policy                                           | `IfNotPresent`                        |
| `storageClass.name`                 | Name of the storageClass                                    | `nfs-client`                          |
| `storageClass.defaultClass`         | Set as the default StorageClass                             | `false`                               |
| `storageClass.allowVolumeExpansion` | Allow expanding the volume                                  | `true`                                |
| `storageClass.reclaimPolicy`        | Method used to reclaim an obsoleted volume                  | `Delete`                              |
| `storageClass.provisionerName`      | Name of the provisionerName                                 | auto (`cluster.local/{fullName}`)     |
| `storageClass.archiveOnDelete`      | Archive pvc when deleting                                   | `true`                                |
| `storageClass.accessModes`          | Set access mode for PV                                      | `ReadWriteOnce`                       |
| `glusterfs.server`                  | IP of the GlusterFS servers (string or array)               | required if endpoints is not provided |
| `glusterfs.volume`                  | GlusteFS volume to mount                                    | required                              |
| `glusterfs.path`                    | Basepath of the mount point to be used                      | `/kubedata`                           |
| `glusterfs.mountOptions`            | Mount options                                               | null                                  |
| `endpoints.create`                  | Should we create an Enpoints resource                       | `true`                                |
| `endpoints.name`                    | Name of the Enpoints resource to use                        | auto if `create`, required else       |
| `endpoints.annotations`             | annotations for the endpoints                               | `{}`                                  |
| `resources`                         | Resources required (e.g. CPU, memory)                       | `{}`                                  |
| `rbac.create`                       | Use Role-based Access Control                               | `true`                                |
| `podSecurityPolicy.enabled`         | Create & use Pod Security Policy resources                  | `false`                               |
| `priorityClassName`                 | Set pod priorityClassName                                   | null                                  |
| `serviceAccount.create`             | Should we create a ServiceAccount                           | `true`                                |
| `serviceAccount.name`               | Name of the ServiceAccount to use                           | auto if `create`, required else       |
| `nodeSelector`                      | Node labels for pod assignment                              | `{}`                                  |
| `affinity`                          | Affinity settings                                           | `{}`                                  |
| `tolerations`                       | List of node taints to tolerate                             | `[]`                                  |
| `deployment.annotations`            | Annotations for the deployment                              | `{}`                                  |
| `pod.annotations`                   | Annotations for the pod                                     | `{}`                                  |

### Deploy without Helm

Get the volume configuration
```bash
export NAMESPACE=default
export GLUSTERIP=x.x.x.x
export GLUSTERVOLUME=volume
export GLUSTERPATH=/kubedata
export ENDPOINTS=glusterfs-client-provisioner
export STORAGECLASS=glusterfs-client
export PROVISIONER=cluster.local/glusterfs
```

Setup the endpoints
```bash
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/endpoints.yaml \
    | sed "s/\( *name:\).*/\1 $ENDPOINTS/g" \
    | sed "s/\( *- ip:\).*/\1 $GLUSTERIP/g" \
    | kubectl apply -n $NAMESPACE -f -
```

Setup the service account
```bash
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/rbac.yaml \
    | sed "s/^\( *namespace:\).*/\1 $NAMESPACE/g" \
    | kubectl apply -n $NAMESPACE -f -
```

Setup the class and the controller
```bash
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/class.yaml \
    | sed "s/^\( *name:\).*/\1 $STORAGECLASS/" \
    | sed "s#^\( *provisioner:\).*#\1 $PROVISIONER#" \
    | kubectl apply -n $NAMESPACE -f -
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/deployment.yaml \
    | sed '/- name: *\(PROVISIONER_NAME\|GLUSTERFS_ENDPOINTS\|GLUSTERFS_PATH\)/{n;d}' \
    | sed "s#\( *\)- name: PROVISIONER_NAME#\0\n\1  value: $PROVISIONER#" \
    | sed "s/\( *\)- name: GLUSTERFS_ENDPOINTS/\0\n\1  value: $ENDPOINTS/" \
    | sed "s#\( *\)- name: GLUSTERFS_PATH#\0\n\1  value: $GLUSTERVOLUME$GLUSTERPATH#" \
    | sed "s/^\( *endpoints:\).*/\1 $ENDPOINTS/" \
    | sed "s#^\( *path:\).*#\1 $GLUSTERVOLUME$GLUSTERPATH#" \
    | kubectl apply -n $NAMESPACE -f -
```

Test the storage class
```bash
export TEST_NS=default
export STORAGECLASS=glusterfs-client
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/test-claim.yaml \
    | sed "s/^\( *storageClassName:\).*/\1 $STORAGECLASS/" \
    | kubectl apply -n $TEST_NS -f -
curl -s https://raw.githubusercontent.com/olli-ai/glusterfs-subdir-external-provisioner/master/deploy/test-pod.yaml \
    | kubectl apply -n $TEST_NS -f -
```
