#!/bin/bash
prob_vm=$1
compete_vm=$2
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
OUTPUT_FILE="./data/obj-latency-noidle$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./data/obj-2$(date +%m%d%H%M).txt"
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


wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    #set up first 8 cores 
    for i in {0..15};do
		virsh vcpupin $select_vm $((i)) $((i))
    done
    sleep 3
}


sleep 5

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm
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
        sudo echo $(($2-$1)) $(($2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1" 
}

#Setting Next 3 cores  as High Latency/Low Capacity 

outputToConsole(){
	echo "phase" >> "$OUTPUT_FILE2"
	echo "$(date '+%Y-%m-%d %H:%M:%S') $(( $(date +%s) - $(date -d "$(date '+%Y-%m-%d %H:00:00')" +%s) ))" | awk '{print $3}' >> "$OUTPUT_FILE2"
}

makeDisaster(){
	virsh vcpupin $prob_vm 3 3
	virsh vcpupin $prob_vm 4 3
	#virsh vcpupin $prob_vm 5 3
	setLatency 1000 20000 0 1
	outputToConsole

}

makeTwoSockets(){
    for i in {8..15};do
                virsh vcpupin $select_vm $((i)) $((i+12))
    done
    for i in {8..15};do
                virsh vcpupin $select_vm $((i)) $((i+12))
    done
    outputToConsole

}

makeAssymetric(){
	setLatency 7000 10000 0 7
	setLatency 3000 10000 8 15
	outputToConsole
}

makeContention(){
        setLatency 8000 10000 0 15
        ssh ubuntu@$compete_vm "sudo $compete_bench" &
        outputToConsole
}

sudo echo 4000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 12000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 1000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
ssh ubuntu@$prob_vm "sudo killall a.out"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/min_granularity_ns <<< 1000000"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/wakeup_granularity_ns <<< 0"
ssh ubuntu@$compete_vm "sudo killall sysbench" 


activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 3 -s 12 -u 8000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/runprober.sh"
    ssh ubuntu@$prob_vm 'sudo bash -c "echo "+cpuset" > /sys/fs/cgroup/cgroup.subtree_control"'
    ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/cpu_prober.out -i 200000 -p 150 -s 1000 &  " & 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/bpf/vcfs/ivh" &
    sleep 10
}
activate_vprobers
#sleep 10
ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes 8;'"
ssh ubuntu@$prob_vm "sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 10000s -c 300 -t 4 https://127.0.0.1:8089/test.html -s /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/new_script.lua" >> "$OUTPUT_FILE" &
sleep 30
makeContention
sleep 30
makeAssymetric
sleep 30
makeDisaster
sleep 30
ssh ubuntu@$prob_vm "sudo killall nginx"
#sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
#sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
#sudo echo 5000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
sudo git add .;sudo git commit -m 'new';sudo git push



