## MetalLB -ийн manifest -ийг apply хийж оруулах
```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.5/config/manifests/metallb-native.yaml
```
## MetalLB -д ашиглах боломжтой сүлжээний хаягийн бүлгийг тохируулах
> Controller -руу энэ тохиргоог оруулж байж speaker -ууд зөв ажиллаж эхлэнэ.

metallb-system гэсэн нэртэй namespace үүсдэг, тэр namespace -руу орж доорх тохиргоог apply хийх ёстой.
```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
namespace: metallb-system
spec:
  addresses:
  - 192.168.3.40-192.168.3.50
```
## L2Advertisment
```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```

## NGINX ingress -ийн manifest -ийг apply хийж оруулах
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.1/deploy/static/provider/cloud/deploy.yaml
```
