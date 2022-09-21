# Metrics server суулгах
https://github.com/kubernetes-sigs/metrics-server сайтаас тохирох release -ийг татаж авна.
Ашиглагдах хоёр файл: `components.yaml`, `high-availability.yaml` 

HA metric server асаая гэвэл high-availability.yaml -ийг нь ашиглаарай. Манай тохиолдолд HA -аар ашиглах шаардлаггүй гэж үзсэн.
`components.yaml` доторх Deployment:metrics-server -ийн containers.args дотор доорх хоёр утгыг оруулна.
```
--kubelet-preferred-address-types=InternalIP
--kubelet-insecure-tls
```

```
kubectl apply -f components.yaml
```



