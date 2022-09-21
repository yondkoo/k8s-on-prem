## LoadBalancer -ийг тохируулж асаах

Машин хоорондын ашиглах дундын хаяг (virtual ip) нь 192.168.3.110 байгаа, сүлжээний хаягаа шалгаж өөрчлөх хэрэгтэй.
##### Keepalived, HAProxy -ийг татах
```
apt update && apt install -y keepalived haproxy
```

Хоёр node дээр /etc/keepalived/check_apiserver.sh гэсэн health check хийдэг скрипт бичих.
```
cat >> /etc/keepalived/check_apiserver.sh <<EOF
#!/bin/sh

errorExit() {
  echo "*** $@" 1>&2
  exit 1
}

curl --silent --max-time 2 --insecure https://localhost:6443/ -o /dev/null || errorExit "Error GET https://localhost:6443/"
if ip addr | grep -q 192.168.3.110; then
  curl --silent --max-time 2 --insecure https://192.168.3.110:6443/ -o /dev/null || errorExit "Error GET https://192.168.3.110:6443/"
fi
EOF

chmod +x /etc/keepalived/check_apiserver.sh
```
##### Keepalived -ийн тохиргоог хийх

/etc/keepalived/keepalived.conf гэсэн дотор тохирогоог оруулна.
```
cat >> /etc/keepalived/keepalived.conf <<EOF
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  timeout 10
  fall 5
  rise 2
  weight -2
}

vrrp_instance VI_1 {
    state BACKUP
    interface eth1
    virtual_router_id 1
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass mysecret
    }
    virtual_ipaddress {
        192.168.3.110
    }
    track_script {
        check_apiserver
    }
}
EOF
```

##### Keepalived -ийг асаах
```
systemctl enable --now keepalived
```

##### HAProxy -ийг тохируулах
```
cat >> /etc/haproxy/haproxy.cfg <<EOF

frontend kubernetes-frontend
  bind *:6443
  mode tcp
  option tcplog
  default_backend kubernetes-backend

backend kubernetes-backend
  option httpchk GET /healthz
  http-check expect status 200
  mode tcp
  option ssl-hello-chk
  balance roundrobin
    server kmaster1 192.168.3.211:6443 check fall 3 rise 2
    server kmaster2 192.168.3.212:6443 check fall 3 rise 2
    server kmaster3 192.168.3.213:6443 check fall 3 rise 2

EOF
```
##### HAProxy -ийг асаах

```
systemctl enable haproxy && systemctl restart haproxy
```
