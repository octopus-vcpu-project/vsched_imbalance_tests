prob_vm=$1
comm_benchmark="/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:8089/test.html" 
#comm_benchmark="/home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 16 -i native"
cpu_benchmark="sysbench --threads=16 --time=10000 cpu run"
virsh shutdown $prob_vm
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
#comm_benchmark_1="/var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:8089/test.html" 
comm_benchmark_1="sleep 65"

for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
done

for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 40))
done





ssh ubuntu@$prob_vm "sudo killall sysbench" 
#blind
OUTPUT_FILE="./tests/numa_inst1$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/numa_inst2$(date +%m%d%H%M).txt"
PLC_OUTPUT="./tests/plc_out$(date +%m%d%H%M).txt"
PLC_OUTPUT2="./tests/plc_out2$(date +%m%d%H%M).txt"
BPF_OUTPUT="./tests/bpf_out23.txt"
PERF_OUTPUT="./tests/perf_out_first$(date +%m%d%H%M).txt"
PERF_OUTPUT2="./tests/perf_out_second$(date +%m%d%H%M).txt"


ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark_1" >> "$OUTPUT_FILE2" 
sleep 10

echo "raw performance test complete"

sudo perf stat -B -o "$PERF_OUTPUT" -C 20-40 -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions &
ssh ubuntu@$prob_vm "sudo $comm_benchmark & sudo $comm_benchmark_1" 
sudo kill -s SIGINT $(pidof perf)

echo "cache test complete"
ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark"&
ssh ubuntu@$prob_vm "sudo $comm_benchmark_1"
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof bpftrace)"
sleep 20
#ssh ubuntu@$prob_vm "sudo su;sudo perf stat -B  -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions 'sudo $comm_benchmark & sudo $comm_benchmark_1'" >> "test.txt"

echo "ipi test complete"
#ssh ubuntu@$prob_vm "sudo $comm_benchmark" &
#ssh ubuntu@$prob_vm "sudo $comm_benchmark_1" &
#for i in {0..20};do 
#   sleep 1
#    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$PLC_OUTPUT"
#done
wait
ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 1000" &

echo "starting smart test suite"
ssh ubuntu@$prob_vm "sudo $comm_benchmark" >> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark_1" >> "$OUTPUT_FILE2" 
echo "test finished"
sleep 20

sudo perf stat -B -o "$PERF_OUTPUT2" -C 20-40 -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions  &
ssh ubuntu@$prob_vm "sudo $comm_benchmark & sudo $comm_benchmark_1" 
sudo kill -s SIGINT $(pidof perf)

sleep 10
ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
ssh ubuntu@$prob_vm "sudo $comm_benchmark"&
ssh ubuntu@$prob_vm "sudo $comm_benchmark_1"
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof bpftrace)"
sleep 20
#ssh ubuntu@$prob_vm "sudo su;sudo perf stat -B  -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions 'sudo $comm_benchmark & sudo $comm_benchmark_1'" >> "test.txt"

#ssh ubuntu@$prob_vm "sudo $comm_benchmark"&
#ssh ubuntu@$prob_vm "sudo $comm_benchmark_1"&
#for i in {0..20};do 
    #sleep 1
    #ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$PLC_OUTPUT2"
#done





sudo git add .;sudo git commit -m 'new';sudo git push