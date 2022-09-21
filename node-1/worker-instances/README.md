## Worker дээр тохируулах тохиргоо

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

#### Master node -оос join хийх token -ийг авч kubeadm join коммандыг ажиллуулна
> Master node дээрээс хийнэ
```shell
kubeadm token generate
```
үүссэн token -ийг доорх комманд дээр ашиглана. $TOKEN
```shell
kubeadm token create $TOKEN --print-join-command
```
дээрх коммандын буцаасан коммандыг worker node -ууд дээр ажиллуулна.

#### Kubelet асахдаа node -ийн eth0 дээр байгаа хаягийг эхлээд авдаг, хэрэв eth0 дээр сүлжээний хаягаа тохируулаагүй бол kubelet.conf дотроос node -ийн сольж оруулна.
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
