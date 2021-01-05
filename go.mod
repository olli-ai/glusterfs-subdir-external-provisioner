module github.com/kubernetes-sigs/nfs-subdir-external-provisioner

go 1.14

require (
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	k8s.io/api v0.17.3
	k8s.io/apimachinery v0.17.3
	k8s.io/client-go v0.17.3
	sigs.k8s.io/sig-storage-lib-external-provisioner/v5 v5.0.0
)
