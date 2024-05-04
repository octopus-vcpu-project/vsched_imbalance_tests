#!/bin/bash
prob_vm=$1
compete_vm=$2
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
OUTPUT_FILE="./data/obj-latency-noidle$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in $(seq 0 15);do
        sudo virsh vcpupin $select_vm $i $((i + 20))
    done

    for i in $(seq 16 31);do
        sudo virsh vcpupin $select_vm $i $((i + 24))
    done
    sleep 2
}
virsh shutdown $prob_vm
virsh shutdown $compete_vm
sleep 5

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
compete_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
compete_vm_cgroup_title=$(sudo cat /proc/$compete_vm_pid/cgroup | awk -F "/" '{print $3}')

#PIN VCPUS and limit CPU usage using CGROUP
#QPS should be low as to avoid competitoin among queues 
ssh ubuntu@$prob_vm "sudo killall sysbench" 


runLatencyTest(){
    latency_option=$1
    echo "Running Latency benchmark $1" 
    echo "Running Latency benchmark $1" >> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$1;time sudo bash run.sh" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "$OUTPUT_FILE" 2>&1
}

setLatency(){
    for i in $(seq 0 31);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq 0 31);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}


runAllTests(){
    runLatencyTest "img-dnn" # QPS=1000 SVC=1ms
    #runLatencyTest "moses" # QPS=300 SVC=100ms
    runLatencyTest "masstree" # QPS=300 SVC=0.5ms
    runLatencyTest "silo" # QPS=1000 SVC=0.3ms
    #runLatencyTest "shore" # QPS=300 SVC=1000ms
    runLatencyTest "specjbb" # QPS=500 SVC=0.2ms
    #runLatencyTest "sphinx" #QPS=1 SVC=3000ms
    runLatencyTest "xapian" QPS=300 SVC=3ms
}

numbers=(16000 8000 4000 2000)
#numbers=(1000)
runTestBlock(){

for i in "${numbers[@]}";do
    setLatency $i
    for i in $(seq 1 3);do
        runAllTests
    done
done
}


#Fetch VM PID and use that to fetch Cgroup title

sudo echo 20000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 20000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 1000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us

ssh ubuntu@$prob_vm "sudo killall a.out"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/min_granularity_ns <<< 1000000"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/wakeup_granularity_ns <<< 0"
ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
sleep 10

runTestBlock

echo "idler added" >> "$OUTPUT_FILE"
ssh ubuntu@$prob_vm "$idler_bench" &
sleep 10
runTestBlock

sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 5000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
sudo git add .;sudo git commit -m 'new';sudo git push


