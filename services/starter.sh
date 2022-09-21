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
    if [ ${#running_vms[@]} -eq "0" ]; then
      VBoxManage startvm "$i" --type headless;
    else
      for j in "${running_vms[@]}"; do
        if [ $i != $j ]; then
          VBoxManage startvm "$i" --type headless;
        fi  
      done
    fi  
  done
}

starter
