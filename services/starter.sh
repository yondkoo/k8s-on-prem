#!/bin/bash

vms=( $(VBoxManage list vms | tr -s '\" {' '%{' | cut -d '%' -f3) )
running_vms=( $(VBoxManage list runningvms | tr -s '\" {' '%{' | cut -d '%' -f3) )

function starter {
  if [ ${#vms[@]} == ${#running_vms[@]} ]; then
    echo "All instances are already running";
    exit 0;
  else
    start_vms;
  fi  
}

function start_vms {
  for i in "${vms[@]}"; do
    if [ $(VBoxManage showvminfo "$i" | grep -c "running (since") -eq "0" ]; then
      VBoxManage startvm "$i" --type headless;
    fi  
  done
}

starter
