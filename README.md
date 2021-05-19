# Remote accessable Minikube Kubernetes Cluster

Instructions on how to setup a Minikube Cluster on Ubuntu. And how to set it up for remote controll via kubectl from another machine.



## Install Kubectl

In order to be able to control the cluster later on we need to install Kubectl first

For that we use snap which might need to be installed first

````shell
sudo apt-get update
sudp apt-get install snap
````

Afterwards simply install kubectl

````shell
sudo snap install kubectl --classic
````

To check if everything is fine prompt the version

````shell
kubectl version
````



## Install Minikube 

Get Package and Install Minikube

````shell
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb
````



## Setup Nginx Proxy for Api-Server

To get a remote connection via kubectl the incomming tcp traffic must be upstreamed to the port exposed from the Minikube Cluster.
In order to do so we need an nginx proxy to handle this upstream

But first we need to know which ip_address to upstream to. This infomation is hidden in the Kubernetes config so we will take a look at that

````shell
kubectl config view
````

The output in the console represents the config yml file from minikubes kubernetes cluster what we need is the server adress wich should look like the one below. 
Write that address down we will need it later

````yaml
server: https://xxx.xxx.xx.xx:8443
````


Install Nginx

````shell
sudo apt-get update
sudo apt-get isntall nginx
````

To check the installation ask for the nginx version

````shell
nginx --version
````

Now we need to setup the upstream. Fot that we need to edit the nginx.cnf file

````shell
sudo nano /etc/nginx/nginx.conf
````

Edit the file to look like this. Note the <minikube_ipadress> thats the one we lokked up in the kubernetes config.
The listen address will be the port on your host machine the remote kubectl will use to connect to the cluster.

````nginx
load_module /usr/lib/nginx/modules/ngx_stream_module.so;

stream {
  server {
      listen 0.0.0.0:51934;
      #TCP traffic will be forwarded to the specified server
      proxy_pass <minikube_ipadress>:8443;
  }
}

events {}
````



## Settingup the firewall

If you want to disable your firewall for some reason you can do so and skip this steps. 
But i highly recommand setting this up. When ever i use the port 51934 you should replace that with what ever you defined in the nginx.conf above

````shell
sudo ufw allow 51934/tcp
sudo ufw enable
````

Check if your firewall is active and has the rules for your port set

````shell
sudo ufw status
````



## Setup the remote connection

This looks like a lot. But its pretty easy if you got trough it ones. 
First we need to clarify two things. From now on i will call the computer you want to use to access your cluster from the **local machine** and the one which hosts you minikube cluster will be the **cluster machine**

Ok so let's get startet by opening the kubernetes config file on you **local machine** it should be in your users home directory under $Home/.kube/config.
Open that file and add the following to the list of **clusters** in the file. Remember the file is a yaml file so use that syntax.

**important:** replace the <ipadress> with the ip address of your **cluster machines** ip address.

````yml
- cluster:
    certificate-authority-data: <ca.crt>
    server: https://<ipaddress>:51999
  name: minikube
````

Add this to the **contexts** list

````yml
- context:
    cluster: minikube
    user: minikube
  name: minikube
````

And this one to the **users** list

````yml
- name: minikube
  user:
    client-certificate-data: <client.crt>
    client-key-data: <ca.key>
````

If you just want to acces this cluster and no other with this instance of kubectl or if the file is empty just use something like this

````yml
apiVersion: v1
current-context: minikube
kind: Config
preferences: {}

clusters:
- cluster:
    certificate-authority-data: 
    server: https://<ipaddress>:51999
  name: minikube
contexts:
- context:
    cluster: minikube
    user: minikube
  name: minikube
users:
- name: minikube
  user:
    client-certificate-data: 
    client-key-data: 
````

Now there are 3 <> left with file names. There is something missing. These are the certificates to authenticate this **local machines** instance of kubectl against the minikube cluster.
The easiest way is to base64 encode the certificates on the **cluster machine** and copy them into the config file on your **local machine**

So on your **cluster machine** use this to encode the files step by step and paste them over to the config file on your **local machine**

The output of this one replaces the <ca.crt>
````shell
base64 ~/.minikube/ca.crt
````

The output of this one replaces the <client.crt>

````shell
base64 ~/.minikube/profiles/minikube/client.crt
````

The output of this one replaces the <client.key>


````shell
base64 ~/.minikube/profiles/minikube/client.key
````

**Important** Make sure the base64 strings are in one line in the config file of your **local machine**

Now your local kubectl should be ready to connect to your minikube cluster once its up and running




## Start Minikube

Start Minikube with a api-server on the ip you want to connect to. This ip address should be the adress of your host machine on which the cluster is running.
If the cluster is behind some other proxy or what ever it has to be the adress of the first proxy the request will hit. It can even be a domain if you want to.
Just make shure its the same one used before to setup the config file on your **local machine**

````shell
minikube start --apiserver-ips=<ipaddress>
````



