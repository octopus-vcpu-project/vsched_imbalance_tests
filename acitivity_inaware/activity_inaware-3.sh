
prob_vm=$1
compete_vm=$2
benchmark_time=20
cache_bench="sysbench --threads=32 --time=30 cpu run"
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-3$(date +%m%d%H%M).txt"

toggle_topological_passthrough(){
    naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
    smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
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
    sudo bash ../utility/cleanon_startup.sh $prob_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done

    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 24))
    done
    echo "Pinning Complete"
    ssh ubuntu@$prob_vm "sudo killall mysqld"
} 


wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i + 20))
    done

    for i in {16..31};do
        sudo virsh vcpupin $select_vm $i $((i + 24))
    done
    sleep 2
}

setLatency(){
    set_latency=$1
    sudo echo $1 > /sys/kernel/debug/sched/min_granularity_ns
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}

runTest(){
    test_to_run=$1
    ssh ubuntu@$prob_vm "$test_to_run"  >> "$OUTPUT_FILE" 2>&1
    perf_output="perf.txt"
    sudo perf stat -B -o "$perf_output" -C 20-35,40-55 -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions  &
    ssh ubuntu@$prob_vm "$test_to_run"  
    sudo kill -s SIGINT $(pidof perf)
    cat $perf_output >> $OUTPUT_FILE
}


runAllTests(){
    runTest "sysbench --threads=32 --time=30 cpu run" 
    runTest "./vsched_tests/matmul.out 32 30"
    runTest "cd /home/ubuntu/vsched;sudo bash /home/ubuntu/Workloads/kernbench/kernbench.sh"
    runTest ""
}

virsh shutdown $compete_vm
toggle_topological_passthrough 1
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
ssh ubuntu@$compete_vm "sudo killall ./cache_thr.out"

ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall a.out" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
ssh ubuntu@$prob_vm "sudo $cache_bench"  >> "$OUTPUT_FILE" 
echo "finished warming up"



setLatency 32000000
runAllTests

setLatency 16000000
runAllTests

setLatency 8000000
runAllTests

setLatency 4000000
runAllTests

setLatency 2000000
runAllTests

setLatency 3000000
runAllTests


sudo git add .;sudo git commit -m 'new';sudo git push


