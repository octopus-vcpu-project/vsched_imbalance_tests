#!/bin/bash
prob_vm=$1
compete_vm=$2
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
OUTPUT_FILE="./data/obj-latency-noidle$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 16
    #set up first 12 cores 
    for i in {0..11};do
            if [ $((i % 2)) == 0 ]; then
                virsh vcpupin $select_vm $((i)) $((i))
            else
                virsh vcpupin $select_vm $((i)) $((i+79))
            fi
    done
    for i in {12..13};do
        virsh vcpupin $select_vm $((i)) $((i))
    done
    for i in {14..15};do
        virsh vcpupin $select_vm $((i)) $((14))
    done
    sleep 3
}

virsh shutdown $prob_vm
virsh shutdown $compete_vm
sleep 5

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm
#THIS IS IMPORTANT - LAST CPU MUST BE SENT SOMEWHERE ELSE BECAUSE of stacking restrictions
virsh vcpupin $compete_vm $((15)) $((20))

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
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}

#Setting Next 3 cores  as High Latency/Low Capacity 
setLatency 6000 18000 0 2 #6ms/18ms 

#Setting Next 3 Cores as Low Latency/Low Capacity
setLatency 2000 6000 3 5 #2ms/6ms 

#Setting Next 3 Cores as Low Latency/Low Capacity
setLatency 12000 18000 6 8 #12ms/18ms 

#Setting Next 3 cores  as High Latency/High Capacity 
setLatency 4000 6000 9 11 #4ms/6ms 

#Two Straggler
setLatency 1000 20000 12 13 #1ms/60ms 

#Two Stacking
setLatency 4000 6000 14 15 #4ms/6ms 



sudo echo 18000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 1000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 1000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
ssh ubuntu@$prob_vm "sudo killall a.out"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/min_granularity_ns <<< 1000000"
ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/wakeup_granularity_ns <<< 0"
ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &

runLatencyTest(){
    for i in $(seq 1 3);do
        sleep 3
        latency_option=$1
        echo "Running Latency benchmark $1" 
        echo "Running Latency benchmark $1" >> "$OUTPUT_FILE" 
        ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$1;time sudo bash run.sh" 
        ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "$OUTPUT_FILE" 2>&1
    done
}

runParsecTest(){
    for i in $(seq 1 3);do
        sleep 3
        echo "Running Parsec $1" 
        echo "Running Parsec $1" >> "$OUTPUT_FILE" 
        ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p $1 -n 16 -i native">>"$OUTPUT_FILE"
    done
}


#tailbench
runLatencyTests(){
    runLatencyTest "img-dnn" # QPS=1000 SVC=1ms
    runLatencyTest "moses" # QPS=300 SVC=100ms
    runLatencyTest "masstree" # QPS=300 SVC=0.5ms
    runLatencyTest "silo" # QPS=1000 SVC=0.3ms
    runLatencyTest "shore" # QPS=300 SVC=1000ms
    runLatencyTest "specjbb" # QPS=500 SVC=0.2ms
    runLatencyTest "sphinx" #QPS=1 SVC=3000ms
    runLatencyTest "xapian" #QPS=300 SVC=3ms
}



activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 8 -s 12 -u 8000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/runprober.sh"
    ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/cpu_prober.out -i 200000 -p 100 -s 8000 &  " & 
    sleep 10
}

#parsec
runParsecTests(){
    runParsecTest "blackscholes"
    runParsecTest "bodytrack"
    runParsecTest "canneal" 
    runParsecTest "dedup"
    runParsecTest "facesim" 
    runParsecTest "fluidanimate" 
    runParsecTest "freqmine"
#    runParsecTest "raytrace" 
    runParsecTest "streamcluster"
    runParsecTest "swaptions" 
    runParsecTest "x624"
    runParsecTest "splash2x.barnes"
    runParsecTest "splash2x.fft"
    runParsecTest "splash2x.lu_cb"
    runParsecTest "splash2x.lu_ncb"
    runParsecTest "splash2x.ocean_cp"
    runParsecTest "splash2x.ocean_ncp"
    runParsecTest "splash2x.radiosity"
    runParsecTest "splash2x.radix"
    runParsecTest "splash2x.raytrace"
    runParsecTest "splash2x.volrend"
    runParsecTest "splash2x.water_spatial"
}

sleep 10
#runLatencyTests
runParsecTests

sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 5000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
sudo git add .;sudo git commit -m 'new';sudo git push


