# on-prem k8s cluster

## Vagrant Environment

| Role          | FQDN                      | IP            | OS           | RAM | CPU |
|---------------|---------------------------|---------------|--------------|-----|-----|
| Load Balancer | loadbalancer1.example.com | 192.168.3.51  | Ubuntu 20.04 | 4G  | 2   |
| Load Balancer | loadbalancer2.example.com | 192.168.3.52  | Ubuntu 20.04 | 4G  | 2   |
| Etcd          | etcd1.example.com         | 192.168.3.121 | Ubuntu 20.04 | 2G  | 2   |
| Etcd          | etcd2.example.com         | 192.168.3.122 | Ubuntu 20.04 | 2G  | 2   |
| Etcd          | etcd3.example.com         | 192.168.3.123 | Ubuntu 20.04 | 2G  | 2   |
| Master        | kmaster1.example.com      | 192.168.3.211 | Ubuntu 20.04 | 16G | 4   |
| Master        | kmaster2.example.com      | 192.168.3.212 | Ubuntu 20.04 | 16G | 4   |
| Master        | kmaster3.example.com      | 192.168.3.213 | Ubuntu 20.04 | 16G | 4   |
| Worker        | kworker1.example.com      | 192.168.3.231 | Ubuntu 20.04 | 16G | 4   |
| Worker        | kworker2.example.com      | 192.168.3.232 | Ubuntu 20.04 | 16G | 4   |
| Worker        | kworker3.example.com      | 192.168.3.233 | Ubuntu 20.04 | 16G | 4   |
