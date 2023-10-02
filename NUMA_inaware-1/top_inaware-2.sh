prob_vm=$1
comm_benchmark="sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 30s -c 250 -t 16 https://127.0.0.1:8089/test.html" 
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
#kvm_hv_send_ipi
#what
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
    sudo bash ../utility/cleanon_startup.sh $prob_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $i
    done

    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 4))
    done
    
}
   
OUTPUT_FILE="./tests/numa_inst1$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/numa_inst2$(date +%m%d%H%M).txt"
OUTPUT_FILE3="./tests/perf3$(date +%m%d%H%M).txt"
OUTPUT_FILE4="./tests/perf4$(date +%m%d%H%M).txt"
run_numa_test(){
    comm_bench=$1
    is_nginx=$2
    trace_bpf=$3
    toggle_topological_passthrough 0
    if [ $is_nginx != 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        sleep 5
    fi
    
    ssh ubuntu@$prob_vm "sudo $comm_bench" >> "$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo $comm_bench" >> "$OUTPUT_FILE2" &
    ssh ubuntu@$prob_vm "sudo killall bpftrace;"
    if [ $trace_bpf != 0 ]; then
        #ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$OUTPUT_FILE" &
        sudo perf stat -B -C 0-15,20-35 -o "$OUTPUT_FILE3"  -e l2_rqsts.*,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores,L1-icache-load-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-prefetches,cache-references,cache-misses,cycles,instructions,branches,faults,migrations sleep 30 &
    fi
    wait
    sudo killall perf
    sleep 4
    toggle_topological_passthrough 1
    if [ $is_nginx != 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        sleep 5
    fi
    
    ssh ubuntu@$prob_vm "sudo $comm_bench" >> "$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo $comm_bench" >> "$OUTPUT_FILE2"& 
    if [ $trace_bpf != 0 ]; then
        #ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$OUTPUT_FILE" &
        sudo perf stat -B -C 0-15,20-35 -o "$OUTPUT_FILE4"  -e l2_rqsts.*,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores,L1-icache-load-misses,LLC-loads,LLC-load-misses,LLC-stores,LLC-prefetches,cache-references,cache-misses,cycles,instructions,branches,faults,migrations sleep 30 &
    fi
    ssh ubuntu@$prob_vm "sudo killall bpftrace;"
    wait
    sleep 4
}


run_numa_test "sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 40s -c 200 -t 16 https://127.0.0.1:8089/test.html" 1 1



sudo git add .;sudo git commit -m 'new';sudo git push
