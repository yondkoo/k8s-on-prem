# External Etcd Cluster асаах тохиргоо

Kubernetes -ийн дотоод сервисүүд etcd "key/value" storage -ийг ашиглаж өгөгдлүүдээ хадгалдаг.

### CA тохируулах
Etcd болон kubernetes кластер хоёр хоорондоо TLS ашиглаж өгөгдлөө дамжуулдаг байх ёстой.
TLS -ийг үүсгэхэд ашигласан сертификатуудыг өөр газар нууцлаж хадгалах хэрэгтэй. Дараа нь master node -үүдийг үүсгэхэд ашиглагдана.

##### Шаардлагатай сангуудыг татах
```shell
{
  wget -q --show-progress \
    https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssl \
    https://storage.googleapis.com/kubernetes-the-hard-way/cfssl/1.4.1/linux/cfssljson
  
  chmod +x cfssl cfssljson
  sudo mv cfssl cfssljson /usr/local/bin/
}
```

##### CA -ийг шинээр үүсгэх
> signing.default.expiry дээр 8760h гэснийг сайн анхаараарай! CA -ийн хугацаа дуусахаас өмнө дахин үүнийг сэргээх ёстой.
```shell
{

cat > ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "8760h"
        },
        "profiles": {
            "etcd": {
                "expiry": "8760h",
                "usages": ["signing","key encipherment","server auth","client auth"]
            }
        }
    }
}
EOF

cat > ca-csr.json <<EOF
{
  "CN": "etcd cluster",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "MN",
      "L": "Ulaanbaatar",
      "O": "AI Lab",
      "OU": "ETCD-CA",
      "ST": "Tov"
    }
  ]
}
EOF

cfssl gencert -initca ca-csr.json | cfssljson -bare ca

}
``` 
##### TLS сертификат үүсгэх
Сүлжээний хаягуудыг нягтлаж ETCD1_IP, ETCD2_IP, ETCD3_IP -үүдэд тохирох хаягийг оруулна.
```shell
{

ETCD1_IP="192.168.3.121"
ETCD2_IP="192.168.3.122"
ETCD3_IP="192.168.3.123"

cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "localhost",
    "127.0.0.1",
    "${ETCD1_IP}",
    "${ETCD2_IP}",
    "${ETCD3_IP}"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "MN",
      "L": "Ulaanbaatar",
      "O": "AI Lab",
      "OU": "ETCD-CA",
      "ST": "Tov"
    }
  ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=etcd etcd-csr.json | cfssljson -bare etcd

}
```
##### Etcd node -үүд руу үүсгэсэн сертификатуудыг хуулах

```shell
{

declare -a NODES=(192.168.3.121 192.168.3.122 192.168.3.123)

for node in ${NODES[@]}; do
  scp ca.pem etcd.pem etcd-key.pem root@$node: 
done

}
```
### Etcd node -руу орж доорх коммандуудыг ажиллуулна.
##### Хуулсан сертификатуудыг өөр падруу зөөх
```shell
{
  mkdir -p /etc/etcd/pki
  mv ca.pem etcd.pem etcd-key.pem /etc/etcd/pki/ 
}
```

##### Etcd, etcdctl -уудыг татах
```shell
{
  ETCD_VER=v3.5.1
  wget -q --show-progress "https://github.com/etcd-io/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz"
  tar zxf etcd-v3.5.1-linux-amd64.tar.gz
  mv etcd-v3.5.1-linux-amd64/etcd* /usr/local/bin/
  rm -rf etcd*
}
```

##### Etcd service -ийг systemd дотор тохируулах

> NODE_IP дээр etcd node -ийн сүлжээний хаягийг сольж оруулаарай.

```shell
{

NODE_IP="192.168.3.121"

ETCD_NAME=$(hostname -s)

ETCD1_IP="192.168.3.121"
ETCD2_IP="192.168.3.122"
ETCD3_IP="192.168.3.123"


cat <<EOF >/etc/systemd/system/etcd.service
[Unit]
Description=etcd

[Service]
Type=notify
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/pki/etcd.pem \\
  --key-file=/etc/etcd/pki/etcd-key.pem \\
  --peer-cert-file=/etc/etcd/pki/etcd.pem \\
  --peer-key-file=/etc/etcd/pki/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/pki/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/pki/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${NODE_IP}:2380 \\
  --listen-peer-urls https://${NODE_IP}:2380 \\
  --advertise-client-urls https://${NODE_IP}:2379 \\
  --listen-client-urls https://${NODE_IP}:2379,https://127.0.0.1:2379 \\
  --initial-cluster-token etcd-cluster-1 \\
  --initial-cluster etcd1=https://${ETCD1_IP}:2380,etcd2=https://${ETCD2_IP}:2380,etcd3=https://${ETCD3_IP}:2380 \\
  --initial-cluster-state new
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

}
```

##### Etcd сервисийг асааж, ажиллуулах
```shell
{
  systemctl daemon-reload
  systemctl enable --now etcd
}
```

##### Гурван etcd node -ийг тохируулсан бол шалгах аргууд

```shell
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/pki/ca.pem \
  --cert=/etc/etcd/pki/etcd.pem \
  --key=/etc/etcd/pki/etcd-key.pem \
  member list
```
Арай царайлаг харъяа гэвэл:
```shell
export ETCDCTL_API=3 
export ETCDCTL_ENDPOINTS=https://192.168.3.121:2379,https://192.168.3.122:2379,https://192.168.3.123:2379
export ETCDCTL_CACERT=/etc/etcd/pki/ca.pem
export ETCDCTL_CERT=/etc/etcd/pki/etcd.pem
export ETCDCTL_KEY=/etc/etcd/pki/etcd-key.pem
```

```shell
etcdctl member list
etcdctl endpoint status
etcdctl endpoint health
```

























