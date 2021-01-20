# Kubernetes GlusterFS-Client Provisioner

GlusterFS subdir external provisioner is an automatic provisioner that use your _existing and already configured_ GlusterFS server to support dynamic provisioning of Kubernetes Persistent Volumes via Persistent Volume Claims. Persistent volumes are provisioned as `${namespace}-${pvcName}-${pvName}`.

This is a fork from https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner adapted to GlusterFS.

```sh
make build
# Set a custom image registry to push the container image
# Example REGISTRY="quay.io/myorg"
make image
```

## How to deploy glusterfs-client to your cluster

**glusterfs-client** is an automatic provisioner that use your _existing and already configured_ GlusterFS server to support dynamic provisioning of Kubernetes Persistent Volumes via Persistent Volume Claims. Persistent volumes are provisioned as `${namespace}-${pvcName}-${pvName}`.

To note again, you must _already_ have an GlusterFS Server.

### With Helm

Follow the instructions for the stable helm chart maintained at https://github.com/helm/charts/tree/master/stable/glusterfs-client-provisioner

The tl;dr is

```bash
$ helm install stable/glusterfs-client-provisioner --set glusterfs.endpoints=x.x.x.x --set glusterfs.path=/exported/path
```

### Without Helm

**Step 1: Get connection information for your GlusterFS server**

Make sure your GlusterFS server is accessible from your Kubernetes cluster and get the information you need to connect to it. At a minimum you will need its hostname.

**Step 2: Get the GlusterFS-Client Provisioner files**

To setup the provisioner you will download a set of YAML files, edit them to add your GlusterFS server's connection information and then apply each with the `kubectl` / `oc` command.

Get all of the files in the [deploy](https://github.com/kubernetes-sigs/glusterfs-subdir-external-provisioner/tree/master/deploy) directory of this repository. These instructions assume that you have cloned the [kubernetes-sigs/glusterfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/glusterfs-subdir-external-provisioner/) repository and have a bash-shell open in the root directory.

**Step 3: Setup authorization**

If your cluster has RBAC enabled or you are running OpenShift you must authorize the provisioner. If you are in a namespace/project other than "default" edit `deploy/rbac.yaml`.

**Kubernetes:**

```sh
# Set the subject of the RBAC objects to the current namespace where the provisioner is being deployed
$ NS=$(kubectl config get-contexts|grep -e "^\*" |awk '{print $5}')
$ NAMESPACE=${NS:-default}
$ sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml ./deploy/deployment.yaml
$ kubectl create -f deploy/rbac.yaml
```

**OpenShift:**

On some installations of OpenShift the default admin user does not have cluster-admin permissions. If these commands fail refer to the OpenShift documentation for **User and Role Management** or contact your OpenShift provider to help you grant the right permissions to your admin user.
On OpenShift the service account used to bind volumes does not have the necessary permissions required to use the `hostmount-anyuid` SCC. See also [Role based access to SCC](https://docs.openshift.com/container-platform/4.4/authentication/managing-security-context-constraints.html#role-based-access-to-ssc_configuring-internal-oauth) for more information. If these commands fail refer to the OpenShift documentation for **User and Role Management** or contact your OpenShift provider to help you grant the right permissions to your admin user.

```sh
# Set the subject of the RBAC objects to the current namespace where the provisioner is being deployed
$ NAMESPACE=`oc project -q`
$ sed -i'' "s/namespace:.*/namespace: $NAMESPACE/g" ./deploy/rbac.yaml
$ oc create -f deploy/rbac.yaml
$ oc create role use-scc-hostmount-anyuid --verb=use --resource=scc --resource-name=hostmount-anyuid -n $NAMESPACE
$ oc adm policy add-role-to-user use-scc-hostmount-anyuid system:serviceaccount:$NAMESPACE:glusterfs-client-provisioner
```

**Step 4: Configure the GlusterFS-Client provisioner**

Note: To deploy to an ARM-based environment, use: `deploy/deployment-arm.yaml` instead, otherwise use `deploy/deployment.yaml`.

You must edit the provisioner's deployment file to specify the correct location of your glusterfs-client-provisioner container image.

Next you must edit the provisioner's deployment file to add connection information for your GlusterFS server. Edit `deploy/deployment.yaml` and replace the two occurences of <YOUR GLUSTERFS SERVERS HOSTNAMES> with your server's hostname.

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: glusterfs-client-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: glusterfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: glusterfs-client-provisioner
    spec:
      serviceAccountName: glusterfs-client-provisioner
      containers:
        - name: glusterfs-client-provisioner
          image: quay.io/external_storage/glusterfs-client-provisioner:latest
          volumeMounts:
            - name: glusterfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: fuseim.pri/ifs
            - name: GLUSTERFS_ENDPOINTS
              value: <YOUR GLUSTERFS SERVERS HOSTNAMES>
            - name: GLUSTERFS_PATH
              value: /var/glusterfs
      volumes:
        - name: glusterfs-client-root
          glusterfs:
            endpoints: <YOUR GLUSTERFS SERVERS HOSTNAMES>
            path: /var/glusterfs
```

You may also want to change the PROVISIONER_NAME above from `fuseim.pri/ifs` to something more descriptive like `glusterfs-storage`, but if you do remember to also change the PROVISIONER_NAME in the storage class definition below.

To disable leader election, define an env variable named ENABLE_LEADER_ELECTION and set its value to false.

**Step 5: Deploying your storage class**

**_Parameters:_**

| Name            | Description                                                                                                                                                                  |                             Default                              |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------: |
| onDelete        | If it exists and has a delete value, delete the directory, if it exists and has a retain value, save the directory.                                                          | will be archived with name on the share: `archived-+volume.Name` |
| archiveOnDelete | If it exists and has a false value, delete the directory. if `onDelete` exists, `archiveOnDelete` will be ignored.                                                           | will be archived with name on the share: `archived-+volume.Name` |
| pathPattern     | Specifies a template for creating a directory path via PVC metadata's such as labels, annotations, name or namespace. To specify metadata use `${.PVC.}`: `${PVC.namespace}` |                               n/a                                |

This is `deploy/class.yaml` which defines the GlusterFS-Client's Kubernetes Storage Class:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: managed-glusterfs-storage
provisioner: fuseim.pri/ifs # or choose another name, must match deployment's env PROVISIONER_NAME'
parameters:
  pathPattern: "${.PVC.namespace}/${.PVC.annotations.glusterfs.io/storage-path}" # waits for glusterfs.io/storage-path annotation, if not specified will accept as empty string.
  onDelete: delete
```

**Step 6: Finally, test your environment!**

Now we'll test your GlusterFS provisioner.

Deploy:

```sh
$ kubectl create -f deploy/test-claim.yaml -f deploy/test-pod.yaml
```

Now check your GlusterFS Server for the file `SUCCESS`.

```sh
kubectl delete -f deploy/test-pod.yaml -f deploy/test-claim.yaml
```

Now check the folder has been deleted.

**Step 7: Deploying your own PersistentVolumeClaims**

To deploy your own PVC, make sure that you have the correct `storage-class` as indicated by your `deploy/class.yaml` file.

For example:

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: "managed-glusterfs-storage"
    glusterfs.io/storage-path: "test-path" # not required, depending on whether this annotation was shown in the storage class description
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

# Build and publish with GitHub Actions

In a forked repository you can use GitHub Actions pipeline defined in [.github/workflows/release.yml](.github/workflows/release.yml). The pipeline builds Docker images for `linux/amd64`, `linux/arm64`, and `linux/arm/v7` platforms and publishes them using a multi-arch manifest. The pipeline is triggered when you add a tag like `gh-v{major}.{minor}.{patch}` to your commit and push it to GitHub. The tag is used for generating Docker image tags: `latest`, `{major}`, `{major}:{minor}`, `{major}:{minor}:{patch}`.

The pipeline adds several labels:
* `org.opencontainers.image.title=${{ github.event.repository.name }}`
* `org.opencontainers.image.description=${{ github.event.repository.description }}`
* `org.opencontainers.image.url=${{ github.event.repository.html_url }}`
* `org.opencontainers.image.source=${{ github.event.repository.clone_url }}`
* `org.opencontainers.image.created=${{ steps.prep.outputs.created }}`
* `org.opencontainers.image.revision=${{ github.sha }}`
* `org.opencontainers.image.licenses=${{ github.event.repository.license.spdx_id }}`

**Important:**
* The pipeline performs the docker login command using `REGISTRY_USERNAME` and `REGISTRY_TOKEN` secrets, which have to be provided.
* You also need to provide the `DOCKER_IMAGE` secret specifying your Docker image name, e.g., `quay.io/[username]/glusterfs-subdir-external-provisioner`.
