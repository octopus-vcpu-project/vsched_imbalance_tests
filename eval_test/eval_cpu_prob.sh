e#!/bin/bash
prob_vm=$1
compete_vm=$2
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo taskset -c 0-23 sysbench --threads=32 --time=1000000 cpu run"
OUTPUT_FILE="./data/vprober_react_corr$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./data/vprober_react_set$(date +%m%d%H%M).txt"
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

toggle_topological_passthrough 0
sudo bash ../utility/cleanon_startup.sh $prob_vm 16
toggle_topological_passthrough 1

activate_vprobers(){
    

    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
#    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 30 -s 12 -u 8000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/runprober.sh"
    ssh ubuntu@$prob_vm 'sudo bash -c "echo "+cpuset" > /sys/fs/cgroup/cgroup.subtree_control"'
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/cpu_profiler/a.out -i 200000 -p 100 -s 1000 -v" >> "$OUTPUT_FILE" &
    sleep 10
}
wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    #set up first socket
    for i in {0..15};do
        virsh vcpupin $select_vm $((i)) $((i))
    done
    sleep 3
}
virsh shutdown $compete_vm
sleep 5

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm
#THIS IS IMPORTANT - LAST CPU MUST BE SENT SOMEWHERE ELSE BECAUSE of stacking restrictions
#virsh vcpupin $compete_vm $((11)) $((20))

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
compete_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
compete_vm_cgroup_title=$(sudo cat /proc/$compete_vm_pid/cgroup | awk -F "/" '{print $3}')

ssh ubuntu@$prob_vm "sudo killall sysbench" 

setLatency(){
    for i in $(seq 0 15);do
        sudo echo $1 $(($2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq 0 15);do
        sudo echo $(($2-$1)) $(($2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1"
    echo "Set latency to $1 at $(date +%M\ %S\ %3N | awk '{printf "%d\n", ($1*60000)+($2*1000)+$3}')" >> "$OUTPUT_FILE2"
}
sudo echo 1000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
setLatency 1000 10000
sleep 5
activate_vprobers
ssh ubuntu@$compete_vm "sudo $compete_bench" &
setLatency 1000 10000
sleep 30
setLatency 2000 10000
sleep 10
setLatency 2000 5000 # 40% 
sleep 25
setLatency 3000 5000
sleep 35
setLatency 4000 5000
sleep 15
setLatency 3000 5000
sleep 20
setLatency 2000 5000
sleep 15
setLatency 1000 10000
sleep 3
setLatency 3000 5000
sleep 10
setLatency 4000 5000
sleep 10
ssh ubuntu@$prob_vm "sudo killall a.out" 

sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo git add .;sudo git commit -m 'new';sudo git push


