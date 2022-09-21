## Мастер болон worker хоёр дээр хамтад нь тохируулах тохиргоо

##### Nameserver өөрчлөгдөхөөс зайлс хийж resolvconf -ийг тохируулах

```shell
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf
```

```shell
{
    apt-get update && apt-get install resolvconf
    systemctl enable resolvconf.service
    systemctl start resolvconf.service
}
```

```shell
echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolvconf/resolv.conf.d/head
```

```shell
{
    systemctl restart resolvconf.service
    systemctl restart systemd-resolved.service
    cat /etc/resolv.conf
}
```

##### Swap -ийг зогсоох

```shell
swapoff -a; sed -i '/swap/d' /etc/fstab
```
##### Firewall -ийг зогсоох

```shell
systemctl disable --now ufw
```

##### containerd -тэй холбоотой kernel -ийг ажиллуулах

```shell
{
cat >> /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
}
```

##### kubernetes.conf тохируулах

```shell
{
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system
}
```

##### Containerd ажиллаж орчныг татах
```shell
{
  apt update
  apt install -y containerd apt-transport-https
  mkdir /etc/containerd
  containerd config default > /etc/containerd/config.toml
  systemctl restart containerd
  systemctl enable containerd
}
```

##### Kubeadm, kubelet, kubectl -ийг татах
```shell
{
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
  apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
}
```

```shell
{
  apt update
  apt install -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00
}

```

## Үүнээс доошоо kubeadm ашиглаж kubernetes cluster асаах тохиргоог хийнэ, зөвхөн master node -үүдтэй холбоотой.

Etcd cluster үүсгэхэд ашиглаж байсан CA сертификатуудыг kmaster1, kmaster2, kmaster3 -ийн /etc/kubernetes/pki/etcd дотор хуулж өгнө.
```shell
{

declare -a NODES=(192.168.3.211 192.168.3.212 192.168.3.213)

for node in ${NODES[@]}; do
  scp ca.pem etcd.pem etcd-key.pem root@$node:
done

}
```

##### InitConfiguration болон ClusterConfiguration хоёрын тохиргоо
nodeRegistration.kubeletExtraArgs.node-ip дээр үндсэн kmaster1 -ийн хаягийг өгнө.
controlPlaneEndpoint гэдэг нь apiserver -ийн хаяг, энэ хаягаар дамжуулж cluster -тайгаа харьцана.
podSubnet гэдэг нь cluster дотор ажиллаж pod -уудын авах хаягийн бүлэг.
serviceSubnet гэдэг нь cluster дотор ажиллаж service -уудын хаягийн бүлэг.
localApiEndpoint гэдэг нь master болж орж байгаа node -ийн сүлжээний хаяг.
```shell
{

ETCD1_IP="192.168.3.121"
ETCD2_IP="192.168.3.122"
ETCD3_IP="192.168.3.123"

cat <<EOF > kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "192.168.3.211"
nodeRegistration:
  kubeletExtraArgs:
    node-ip: "192.168.3.211"
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
controlPlaneEndpoint: "192.168.3.110:6443"
etcd:
  external:
    endpoints:
      - https://${ETCD1_IP}:2379
      - https://${ETCD2_IP}:2379
      - https://${ETCD3_IP}:2379
    caFile: /etc/kubernetes/pki/etcd/ca.pem
    certFile: /etc/kubernetes/pki/etcd/etcd.pem
    keyFile: /etc/kubernetes/pki/etcd/etcd-key.pem
networking:
  podSubnet: "10.244.0.0/24"
  serviceSubnet: "10.96.0.0/16"
EOF

}
```

##### kubeadm-config.yaml файлыг kubeadm init ашиглаж cluster -ийг асаах

```shell
kubeadm init --config kubeadm-config.yaml --ignore-preflight-errors=all
```

Дээрх коммандыг ажиллуулахад etcd cluster -руу холбогдож, kubeadm-config дотор тодорхойлсон тохиргооны дагуу cluster асна.


##### Cluster ассаны дараа network-plugin -ийг суулгана. Calico гэдэг нэртэй network plugin ашиглаж байгаа

```shell
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
```
##### kmaster1 -ийн node resource яг InitConfiguration дээр тодорхойлсоноор ассан эсэхийг шалгана. (Үүнийг kmaster2, kmaster3, kworker1, kworker2, kworker3 тус бүрд нь шалгах ёстой) 
```shell
kubectl get nodes kmaster1 -o yaml
```

## Үүнээс хойш бусад master -тай холбоотой тохиргоог хийнэ.

##### Cluster үүссэний дараа join token үүсдэг
`--control-plane` -тэй token -ийг бусад master node -үүд дээрээ ажиллуулана
> Master node join хийхдээ үндсэн master -ийн /etc/kubernetes/admin.conf файл болон /etc/kubernetes/pki дотор байгаа сертификатуудыг тухайн node -ийн /etc/kubernetes директор дотор хуулж оруулсан байх ёстой.

Cluster үүсэхэд үүссэн, бусад мастеруудад ашиглагдах сертификатууд:

    1. sa.key
    2. sa.pub
    3. front-proxy-client.key
    4. front-proxy-client.crt
    5. ca.crt
    6. ca.key
    7. front-proxy-ca.crt
    8. front-proxy-ca.key
  
```shell
{

cd /etc/kubernetes/pki

declare -a NODES=(192.168.3.212 192.168.3.213)

for node in ${NODES[@]}; do
  scp sa.key sa.pub front-proxy-client.key front-proxy-client.crt ca.crt ca.key front-proxy-ca.crt front-proxy-ca.key root@$node:/etc/kubernetes/pki
done

}
```

admin.conf -ийг хуулах
```shell
{

cd /etc/kubernetes

declare -a NODES=(192.168.3.212 192.168.3.213)

for node in ${NODES[@]}; do
  scp admin.conf root@$node:/etc/kubernetes
done

}
```
#### Kubelet асахдаа node -ийн eth0 дээр байгаа хаягийг эхлээд авдаг, хэрэв eth0 дээр сүлжээний хаягаа тохируулаагүй бол kubelet.conf дотроос бусад master -ийн хаягуудыг сольж оруулна.
> Kubelet -ийн дээр node -ийн хаягийг зөв тохируулагүй тохиолдолд pod, service -ууд руу хандаж чадахгүй, resource -ийн алдаа гарна.
```shell
IP_ADDRESS=энэ утга дээр node -ийн сүлжээний хаягаа бичнэ
```
```shell
echo "Environment=\"KUBELET_EXTRA_ARGS=--node-ip=$IP_ADDRESS\"" >> /etc/systemd/system/kubelet.service.d/10-kubeadm.conf

{
  systemctl daemon-reload
  systemctl stop kubelet
  systemctl start kubelet
}
```

kubeadm join xxxxxxxxx --control-plane гэсэн коммандыг ажиллуулсаны дараа дээр дурьдсан `kubectl get nodes node_name -o yaml` гэсэн коммандыг ажиллуулж node-ip дээр тохируулсан хаяг чинь орсон эсэхийг шалгана.
