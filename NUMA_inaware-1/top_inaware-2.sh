prob_vm=$1
comm_benchmark="sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:8089/test.html" 
cpu_benchmark="sysbench --threads=16 --time=10000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"


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
    ssh ubuntu@$prob_vm "sudo killall nginx"
    ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
    sleep 5
}




ssh ubuntu@$prob_vm "sudo killall sysbench" 
toggle_topological_passthrough 0
#blind
OUTPUT_FILE="./tests/numa_inst1$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/numa_inst2$(date +%m%d%H%M).txt"
BPF_OUTPUT="./tests/bpf_out$(date +%m%d%H%M).txt"
PERF_OUTPUT="./tests/perf_out$(date +%m%d%H%M).txt"

#ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$OUTPUT_FILE" &
#ssh ubuntu@$prob_vm "sudo $cpu_benchmark &" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE2" 

ssh ubuntu@$prob_vm "sudo killall bpftrace;sudo killall sysbench" 

echo "test finished"
sleep 8

ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark"
ssh ubuntu@$prob_vm "sudo killall bpftrace;sudo killall sysbench" 
sleep 8

sudo perf stat -B -o "$PERF_OUTPUT"  -e l2_rqsts.miss,l2_rqsts.references,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores,L1-icache-load-misses,LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions,branches,faults,migrations ssh ubuntu@$prob_vm "sudo $comm_bench & sudo $comm_bench"

toggle_topological_passthrough 1
#ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE2" 
ssh ubuntu@$prob_vm "sudo killall bpftrace;sudo killall sysbench" 
echo "test finished"
sleep 8

ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark"
ssh ubuntu@$prob_vm "sudo killall bpftrace;sudo killall sysbench" 
sleep 8

sudo perf stat -B -o "$PERF_OUTPUT"  -e l2_rqsts.miss,l2_rqsts.references,L1-dcache-load-misses,L1-dcache-loads,L1-dcache-stores,L1-icache-load-misses,LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions,branches,faults,migrations ssh ubuntu@$prob_vm "sudo $comm_bench & sudo $comm_bench"

#ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$OUTPUT_FILE" &
sleep 3





sudo git add .;sudo git commit -m 'new';sudo git push