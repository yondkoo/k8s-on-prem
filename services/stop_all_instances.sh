#!/bin/bash

running_vms=( $(VBoxManage list runningvms | tr -s '\" {' '%{' | cut -d '%' -f3) )

for element in "${running_vms[@]}"; do
  VBoxManage controlvm "$element" poweroff;
done

