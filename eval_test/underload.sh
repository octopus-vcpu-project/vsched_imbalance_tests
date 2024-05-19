#!/bin/bash
prob_vm=$1
compete_vm=$2
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
OUTPUT_FILE="./data/obj-latency-noidle$(date +%m%d%H%M).txt"
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='1' dies='1' cores='16' threads='1'/></cpu>"
toggle_topological_passthrough(){
    virsh shutdown $prob_vm
    while true; do
        vm_state=$(virsh domstate "$prob_vm")
        if [ "$vm_state" != "running" ]; then
            echo "VM is shutdown"
            break
        else
            echo "Waiting for VM to shutdown"
            sleep 3 
        fi
    done
    virsh dumpxml $prob_vm > /tmp/$prob_vm.xml
    if [ $1 -eq 1 ]; then
        sed -i "/<cpu /,/<\/cpu>/c\\$smart_topology_string" /tmp/$prob_vm.xml
    else
        sed -i "/<cpu /,/<\/cpu>/c\\$naive_topology_string" /tmp/$prob_vm.xml
    fi
    virsh define /tmp/$prob_vm.xml
    sleep 5
}



wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    #set up first 8 cores 
    for i in {0..15};do
		virsh vcpupin $select_vm $((i)) $((i))
    done
    sleep 3
}
#THIS IS IMPORTANT - LAST CPU MUST BE SENT SOMEWHERE ELSE BECAUSE of stacking restrictions

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
compete_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
compete_vm_cgroup_title=$(sudo cat /proc/$compete_vm_pid/cgroup | awk -F "/" '{print $3}')

ssh ubuntu@$prob_vm "sudo killall sysbench" 

setLatency(){
    for i in $(seq $3 $4);do
        sudo echo $1 $(($2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq $3 $4);do
        sudo echo $((4000)) $((8000)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}

#Setting Next 3 cores  as High Latency/Low Capacity 
setLatency 4000 8000 0 15 #6ms/18ms 




sudo echo 4000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 12000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 1000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
