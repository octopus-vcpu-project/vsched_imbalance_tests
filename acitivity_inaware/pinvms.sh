#!/bin/bash


for i in $(seq 0 15);do
    sudo virsh vcpupin $1 $i $((i + 20))
done

for i in $(seq 16 31);do
    sudo virsh vcpupin $1 $i $((i + 24))
done
