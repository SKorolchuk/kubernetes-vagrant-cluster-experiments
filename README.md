# Vagrant Kubernetes cluster configuration for Ubuntu-based VM on Hyper-V

Building a 2 node Windows/Linux cluster

Once you have some of the basics down with Kubernetes, it's time to build a larger cluster with both Windows & Linux nodes.

This tutorial will create a Kubernetes master running in a Linux VM, which can also be used to run containers. Once the master is up, the Windows host will be added to the same cluster. The same steps could be used to join other existing machines as well, or you could create even more VMs to join as needed.
Prerequisites

    Windows 10 Anniversary Update, Windows Server 2016 or later
    Hyper-V role installed
    Vagrant 1.9.3 or later for Windows 64-bit



### Setting up the Linux master with ubuntu

Get a clean ubuntu image up

```powershell
vagrant box add ubuntu-16
# Choose hyperv provider when prompted
vagrant init ubuntu-16
vagrant up
```


This also has Vagrant provisioner steps to:

- Install docker from ubuntu package repo
- Install latest versions of kubectl & kubeadm from Kubernetes package repo
- Initialize a simple cluster with `kubeadm init`



### Step 1 - Start the Kubernetes master

`vagrant up master`

The last provisioner step in the `Vagrantfile` runs `install-k8s.sh` which will install all the packages and create a Kubernetes master. These steps were adapted from the [official guide](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/)


```none
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.7.3
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks
[preflight] Some fatal errors occurred:
        user is not running as root
[preflight] If you know what you are doing, you can skip pre-flight checks with `--skip-preflight-checks`
[vagrant@localhost ~]$ sudo kubeadm init
[kubeadm] WARNING: kubeadm is in beta, please do not use it for production clusters.
[init] Using Kubernetes version: v1.7.3
[init] Using Authorization modes: [Node RBAC]
[preflight] Running pre-flight checks
[kubeadm] WARNING: starting in 1.8, tokens expire after 24 hours by default (if you require a non-expiring token use --token-ttl 0)
[certificates] Generated CA certificate and key.
[certificates] Generated API server certificate and key.
[certificates] API Server serving cert is signed for DNS names [localhost.localdomain kubernetes kubernetes.default kubernetes.default.
svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.1.159]
[certificates] Generated API server kubelet client certificate and key.
[certificates] Generated service account token signing key and public key.
[certificates] Generated front-proxy CA certificate and key.
[certificates] Generated front-proxy client certificate and key.
[certificates] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/controller-manager.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/scheduler.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/admin.conf"
[kubeconfig] Wrote KubeConfig file to disk: "/etc/kubernetes/kubelet.conf"
[apiclient] Created API client, waiting for the control plane to become ready
[apiclient] All control plane components are healthy after 66.029744 seconds
[token] Using token: 11e173.294ee115d41e8df3
[apiconfig] Created RBAC rules
[addons] Applied essential addon: kube-proxy
[addons] Applied essential addon: kube-dns

Your Kubernetes master has initialized successfully!

To start using your cluster, you need to run (as a regular user):

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  http://kubernetes.io/docs/admin/addons/

You can now join any number of machines by running the following on each node
as root:

  kubeadm join --token 11e173.294ee115d41e8df3 192.168.1.159:6443
```

There are two important areas you need to save for later:

- The kube config
- The kubeadm join line


#### Getting the kube config
First, get a copy of the kubeadm config into your home directory in the ubuntu VM. Connect with `vagrant ssh master` for the next step

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

And confirm it works inside the ubuntu VM with `kubectl get node`

```none
[vagrant@localhost ~]$ kubectl get node
NAME                    STATUS     AGE       VERSION
localhost.localdomain   NotReady   32m       v1.7.3
```

#### Getting the kubeadm join script

Normally, the Vagrant synced folders would make this easy but there's a few limitations with Vagrant on Windows. Instead, a manual step is needed to copy the node join info back to the host before starting the next VMs.

```powershell
if ((test-path tmp) -eq $false) { mkdir tmp }
vagrant ssh -c 'cat /vagrant/tmp/join.sh' master | out-file -encoding ascii "tmp/join.sh"
```


### Setting up Flannel on master

Connect to the master with `vagrant ssh master`

Now, get the default flannel configuration and deploy it:

```bash
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -o kube-flannel.yml
kubectl apply -f kube-flannel.yml
```

Check that it started up with `kubectl get pod --all-namespaces`. Within a minute or two, at least one instance of `kube-flannel-ds` and `kube-dns` should be running. Wait for those before moving on - `kubectl get pod --all-namespaces -w` makes it easy.

```none
NAMESPACE     NAME                                         READY     STATUS    RESTARTS   AGE
kube-system   etcd-master.localdomain                      1/1       Running   0          9m
kube-system   kube-apiserver-master.localdomain            1/1       Running   0          9m
kube-system   kube-controller-manager-master.localdomain   1/1       Running   0          9m
kube-system   kube-dns-6f4fd4bdf-m6wv4                     3/3       Running   0          10m
kube-system   kube-flannel-ds-ph6c2                        1/1       Running   0          1m
kube-system   kube-flannel-ds-whf4g                        1/1       Running   0          1m
kube-system   kube-proxy-gt2ht                             1/1       Running   0          10m
kube-system   kube-proxy-jrvqf                             1/1       Running   0          3m
kube-system   kube-scheduler-master.localdomain            1/1       Running   0          9m
```


### Managing the Kubernetes cluster from Windows

Now, it's time to get the config file needed out of the VM and onto your Windows machine

```powershell
mkdir ~/.kube
vagrant ssh  -c 'cat ~/.kube/config' master | out-file ~/.kube/config -encoding ascii
```

If you don't already have kubectl.exe on your machine and in your path, there's a few different 
ways you can do it. The `kubernetes-cli` [choco package](https://chocolatey.org/packages/kubernetes-cli) 
is probably the easiest - `choco install kubernetes-cli`. If you want to do this manually - look for the `kubernetes-client-windows-amd64.tgz` download in the [Kubernetes 1.10 release notes](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.10.md#client-binaries)

> Tip: Later you can use `choco upgrade kubernetes-cli` to get a new release

Now, `kubectl get node` should work on the Windows host.

### Joining a Linux node

The `Vagrantfile` also includes another Linux VM called "nodea". After setting up the master, be sure you
ran the extra step to copy `join.sh` back to the host before going forward.

`vagrant up nodea` will bring up the Linux node. You can check with `kubectl get node`

    PS C:\Users\patrick\Source\windows-k8s-lab> kubectl get node
    NAME                 STATUS    ROLES     AGE       VERSION
    master.localdomain   Ready     master    8m        v1.10.0
    nodea.localdomain    Ready     <none>    36s       v1.10.0

### Run a Linux service to test it out

If you are still SSH'd to a Linux node, go ahead and type `exit` to disconnect. Next we'll bring it all together and use kubectl on Windows to deploy a service to the Linux nodes, then connect to it.

These next steps will show:

1. Creating a deployment `hello` that will run a container called `echoserver`
2. Creating a service that's accessible on the node's IP 
3. Connecting and making sure it works

```powershell
kubectl run hello --image=gcr.io/google_containers/echoserver:1.10 --port=8080
kubectl get pod -o wide
```

Now you should have a pod running:

    NAME                     READY     STATUS    RESTARTS   AGE       IP           NODE
    hello-794f7449f5-rmdjt   1/1       Running   0          25m       10.244.1.4   nodea.localdomain

If not, wait and check again. It may take from a few seconds to a few minutes depending on how fast your host and internet connection are.

```powershell
kubectl expose deploy hello --type=NodePort
kubectl get service
```

Now it has a service listening on each node's external IP, but the port (31345 in this example) will vary

    NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
    hello        NodePort    10.111.75.166   <none>        8080:31345/TCP   20h
    kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP          1d

You can easily get each Linux node's IP from Hyper-V Manager, with `Get-VMNetwork`, or `vagrant ssh-config`. Get the IP of each node, and try to access the service running on the nodeport:

```powershell
(Invoke-WebRequest -UseBasicParsing http://192.168.1.139:31345).RawContent
```

Which will return something like this:

    HTTP/1.1 200 OK
    Transfer-Encoding: chunked
    Connection: keep-alive
    Content-Type: text/plain
    Date: Thu, 28 Dec 2017 10:42:59 GMT
    Server: nginx/1.10.0

    CLIENT VALUES:
    client_address=10.244.1.1
    command=GET
    real path=/
    query=nil
    request_version=1.1
    request_uri=http://192.168.1.139:8080/

    SERVER VALUES:
    server_version=nginx: 1.10.0 - lua: 10001

    HEADERS RECEIVED:
    host=192.168.1.139:31345
    user-agent=Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.16299.98
    BODY:
    -no body in request-


Try another cluster node's external IP if you want to make sure the Kubernetes cluster network is working ok. The client_address will change showing you accessed it from a different cluster node.

    HTTP/1.1 200 OK
    Transfer-Encoding: chunked
    Connection: keep-alive
    Content-Type: text/plain
    Date: Thu, 28 Dec 2017 10:44:56 GMT
    Server: nginx/1.10.0

    CLIENT VALUES:
    client_address=10.244.0.0
    command=GET
    real path=/
    query=nil
    request_version=1.1
    request_uri=http://192.168.1.138:8080/

    SERVER VALUES:
    server_version=nginx: 1.10.0 - lua: 10001

    HEADERS RECEIVED:
    connection=Keep-Alive
    host=192.168.1.138:31345
    user-agent=Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.16299.98
    BODY:
    -no body in request-


Now the service is up and running on nodea! Once you're done, delete the service and deployment to clean
everything back up.

```bash
kubectl delete deploy hello
kubectl delete service hello
```

### Joining the Windows node

> Work in progress

Steps to be adapted from https://kubernetes.io/docs/getting-started-guides/windows/ or https://github.com/apprenda/kubernetes-ovn-heterogeneous-cluster

Find latest binaries at:
https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md

Using [1.10.0](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG-1.10.md#node-binaries):
- [Windows node](https://dl.k8s.io/v1.10.0/kubernetes-node-windows-amd64.tar.gz)

## References

- [Getting Started Guide - Windows](https://kubernetes.io/docs/getting-started-guides/windows/)
- [Kubernetes the Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)


## Building a 1-node Linux-based cluster with Minikube on Windows 10

Minikube sets up a quick 1-node Linux-only Kubernetes cluster in a VM. However, it can't add other nodes such as a Windows host. If you just want to run a few Linux containers to try Kubernetes out, this is a good way to start.

The download links & full guide are at https://github.com/kubernetes/minikube , but here's a brief summary.
