ssh "To Your Node Designated as Master"

##################### Run this on other nodes #######################

#Update the server
sudo apt-get update -y
sudo apt-get upgrade -y

#Install containerd
sudo apt-get install containerd -y

#Configure containerd and start the service
sudo mkdir -p /etc/containerd
sudo su -
containerd config default  /etc/containerd/config.toml
exit

#Next, install Kubernetes. First you need to add the repository's GPG key with the command:
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add

#Add the Kubernetes repository
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

#Install all of the necessary Kubernetes components with the command:
sudo apt-get install kubeadm kubelet kubectl -y

#Modify "sysctl.conf" to allow Linux Node’s iptables to correctly see bridged traffic
sudo nano /etc/sysctl.conf
    #Add this line: net.bridge.bridge-nf-call-iptables = 1

sudo -s
#Allow packets arriving at the node's network interface to be forwaded to pods. 
sudo echo '1' > /proc/sys/net/ipv4/ip_forward
exit

#Reload the configurations with the command:
sudo sysctl --system

#Load overlay and netfilter modules 
sudo modprobe overlay
sudo modprobe br_netfilter

#Add other all nodes to hosts file. Change the IP and server names to match your installation. 
sudo nano /etc/hosts
    192.168.0.60 ubuntu-server1
    192.168.0.61 ubuntu-server2
    
#Disable swap by opening the fstab file for editing 
sudo nano /etc/fstab
    #Comment out "/swap.img"

#Disable swap from comand line also 
sudo swapoff -a

#Pull the necessary containers with the command:
sudo kubeadm config images pull

####### This section must be run only on the Master node#############

#**Note: SSH to your master if not already connected.

sudo kubeadm init 
#Make sure you copy the "kubeadm join" command at the end of above operation, you'lll need to run it on non-master nodes.

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#Download Calico CNI
curl https://docs.projectcalico.org/manifests/calico.yaml > calico.yaml
#Apply Calico CNI
kubectl apply -f ./calico.yaml

scp -r $HOME/.kube YourID@Non_Master_Node_IP:/home/YourID

exit
##################### Run this on other nodes #######################

ssh "YourID@Non_Master_Node_IP"
    
sudo -i 
    #Paste the token "kubeadm join" command you got from "kubeadm init" operation and run it below
    
exit

############################################################################Test Cluster#########################################################################
#Get cluster info
kubectl cluster-info

#View nodes (one in our case)
kubectl get nodes

#Untaint maste
#kubectl taint node ubuntu-server1 node-role.kubernetes.io/master-

#Schedule a Kubernetes deployment using a container from Google samples
kubectl create deployment hello-world --image=gcr.io/google-samples/hello-app:1.0

#View all Kubernetes deployments
kubectl get deployments

#Get pod info
kubectl get pods -o wide

#Scale up the replica set to 4
kubectl scale --replicas=2 deployment/hello-world

#Get pod info
kubectl get pods -o wide









#Create a Kubernetes service to expose our service
kubectl expose deployment hello-world --port=8080 --target-port=8080 --type=NodePort

#Get all deployments in the current name space
kubectl get services -o wide

  
curl http://10.98.39.222:8080

#Test the service using Nodeport
curl   http://localhost:32563

#Shell to the pod
kubectl exec -it hello-world-5457b44555-cgvtr     -- sh
exit

#Clean up
kubectl delete deployment hello-world
kubectl delete service hello-world

*******************************************************************************************************
#Add curl to POD
apk --no-cache add curl

#From inside cluster we can do
curl http://hello-world:8080
    #rather than ClusterIP
        curl http://10.99.252.65:8080


#kubeadm reset command. this will un-configure the kubernetes cluster.
