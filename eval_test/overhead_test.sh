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

wake_and_pin_vm $prob_vm

ssh ubuntu@$prob_vm "sudo killall sysbench" 

runLatencyTest(){
    for i in $(seq 1 3);do
        sleep 3
        echo "Running Latency benchmark $1" 
        echo "Running Latency benchmark $1" >> "$OUTPUT_FILE" 
        ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$1;time sudo bash run.sh" 
        ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "$OUTPUT_FILE" 2>&1
    done
}

runPhoronixTest(){
    for i in $(seq 1 1);do
        sleep 3
        echo "Running Phoronix $1" 
        echo "Running Phoronix $1" >> "$OUTPUT_FILE" 
        ssh ubuntu@$prob_vm "sudo phoronix-test-suite batch-run $1">>"$OUTPUT_FILE"
    done
}


runPhoronixTests(){
	runPhoronixTest "compress-pbzip2"
	runPhoronixTest "build-imagemagick"
}

runParsecTest(){
    for i in $(seq 1 3);do
        sleep 3
        ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p $1 -n 16 -i native">>"$OUTPUT_FILE"
	sleep 3
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

#parsec
runParsecTests(){
#    runParsecTest "blackscholes"
#    runParsecTest "bodytrack"
#    runParsecTest "canneal" 
    runParsecTest "dedup"
    runParsecTest "facesim" 
#    runParsecTest "fluidanimate" 
 #   runParsecTest "freqmine"
#    runParsecTest "raytrace" 
    runParsecTest "streamcluster"
 #   runParsecTest "swaptions" 
 #   runParsecTest "x624"
 #   runParsecTest "splash2x.barnes"
    runParsecTest "splash2x.fft"
  #  runParsecTest "splash2x.lu_cb"
    runParsecTest "splash2x.lu_ncb"
    runParsecTest "splash2x.ocean_cp"
    runParsecTest "splash2x.ocean_ncp"
  #  runParsecTest "splash2x.radiosity"
    runParsecTest "splash2x.radix"
   # runParsecTest "splash2x.raytrace"
   # runParsecTest "splash2x.volrend"
   # runParsecTest "splash2x.water_spatial"
}

activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 10 -s 12 -d 400 -u 17000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/runprober.sh"
    ssh ubuntu@$prob_vm 'sudo bash -c "echo "+cpuset" > /sys/fs/cgroup/cgroup.subtree_control"'
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/cpu_profiler/cpu_prober.out -i 200000 -p 100 -s 2000  " & 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/bpf/vcfs/atc" &
    sleep 10
}

virsh shutdown $compete_vm
#runParsecTests
#runLatencyTests
activate_vprobers
sleep 10
#runParsecTests
runLatencyTests

#sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
#sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
#sudo echo 5000 > /proc/sys/kernel/sched_cfs_bandwidth_slice_us
sudo git add .;sudo git commit -m 'new';sudo git push



