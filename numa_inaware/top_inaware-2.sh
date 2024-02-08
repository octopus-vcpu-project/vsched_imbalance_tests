prob_vm=$1
bench_1_=("/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 30s -c 300 -t 8 https://127.0.0.1:8089/test.html" )
#bench_1_+=("/home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 16 -i native")
#bench_1_+=("sudo hackbench -s 2000 -g 4 -f 2 -l 4000000 -T 8")


bench_2_=("/var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/wrk-4.2.0/wrk -d 30s -c 300 -t 8 https://127.0.0.1:4054/test.html" )
#bench_2_+=("/home/ubuntu/Workloads/parsec-bench/bin/parsecmgmt -a run -p dedup -n 16 -i native")
#bench_2_+=("sudo hackbench -s 2000 -g 4 -f 2 -l 4000000 -T 8")

comm_benchmark="/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:8089/test.html" 
#comm_benchmark="/home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 16 -i native"
cpu_benchmark="sysbench --threads=16 --time=10000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
comm_benchmark_1="/var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:4054/test.html" 
#comm_benchmark_1="sleep 65"

for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
done

for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 40 ))
done

toggle_topological_passthrough(){
   echo "Pinning Complete"
   ssh ubuntu@$prob_vm "sudo killall nginx"
  # ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
   #ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
   sleep 10
   ssh ubuntu@$prob_vm "sudo killall mysqld"
} 




ssh ubuntu@$prob_vm "sudo killall sysbench" 
toggle_topological_passthrough 0
#blind
OUTPUT_FILE="./tests/numa_inst1$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/numa_inst2$(date +%m%d%H%M).txt"
PLC_OUTPUT="./tests/plc_out$(date +%m%d%H%M).txt"
PLC_OUTPUT2="./tests/plc_out2$(date +%m%d%H%M).txt"
BPF_OUTPUT="./tests/bpf_out23.txt"
PERF_OUTPUT="./tests/perf_out_first$(date +%m%d%H%M).txt"
PERF_OUTPUTa2="./tests/perf_out_second$(date +%m%d%H%M).txt"

run_cpu_bench() {
    local cpu_bench=$1
    local cpu_bench_1=$2
    echo "first pass"
    ssh ubuntu@$prob_vm "sudo $cpu_bench"&
    ssh ubuntu@$prob_vm "sudo $cpu_bench_1"
    sleep 5
}

run_cpu_bench_output() {
    local cpu_bench=$1
    local cpu_bench_1=$2
    echo "first pass"
    ssh ubuntu@$prob_vm "sudo $cpu_bench" >> "$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo $cpu_bench_1" >> "$OUTPUT_FILE2" 
    sleep 5
}
ssh ubuntu@$prob_vm "sudo sysbench cpu run --time=10 --threads=64  "
length=${#bench_1_[@]}
for ((i=0; i<length; i++)); do
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi 
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}
    run_cpu_bench_output "$bench_1" "$bench_2"
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi 
done
sleep 10

echo "raw performance test complete"

length=${#bench_1_[@]}
for ((i=0; i<length; i++)); do
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi 
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}
    sudo /home/vsched/tools/perf/perf stat -B -o "${PERF_OUTPUT}_$i" -C 20-35,40-55 -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions &
    ssh ubuntu@$prob_vm "sudo $bench_1 & sudo $bench_2" 
    sudo kill -s SIGINT $(pidof perf)
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi 
    sleep 3
done


echo "cache test complete"
length=${#bench_1_[@]}
for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
    run_cpu_bench "$bench_1" "$bench_2"
    ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof bpftrace)"
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi 
done
sleep 3
#ssh ubuntu@$prob_vm "sudo su;sudo perf stat -B  -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions 'sudo $comm_benchmark & sudo $comm_benchmark_1'" >> "test.txt"

echo "ipi test complete"
#ssh ubuntu@$prob_vm "sudo $comm_benchmark" &
#ssh ubuntu@$prob_vm "sudo $comm_benchmark_1" &
#for i in {0..20};do 
#   sleep 1
#    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$PLC_OUTPUT"
#done
ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 1000" &
sleep 5
echo "starting smart test suite"
ssh ubuntu@$prob_vm "sudo sysbench cpu run --time=10 --threads=64  "
for ((i=0; i<length; i++)); do
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}
    run_cpu_bench_output "$bench_1" "$bench_2"
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi
done
sleep 10

echo "raw performance test complete"
for ((i=0; i<length; i++)); do
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}
    sudo /home/vsched/tools/perf/perf stat -B -o "${PERF_OUTPUTa2}_$i" -C 20-35,40-55 -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions &
    ssh ubuntu@$prob_vm "sudo $bench_1 & sudo $bench_2" 
    sudo kill -s SIGINT $(pidof perf)
    sleep 3
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi
done


echo "cache test complete"


for ((i=0; i<length; i++)); do
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;' -c /var/lib/phoronix-test-suite/installed-tests/pts/new-nginx-3/nginx_/conf/nginx.conf"
        sleep 5
    fi
    bench_1=${bench_1_[$i]}
    bench_2=${bench_2_[$i]}

    ssh ubuntu@$prob_vm "sudo /home/ubuntu/bpftrace/build/src/bpftrace -e 'kfunc:native_send_call_func_single_ipi { @[cpu] = count(); }' &" >> "$BPF_OUTPUT" &
    run_cpu_bench "$bench_1" "$bench_2"
    ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof bpftrace)"
    sleep 3
    if [ $i -eq 0 ]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
    fi
done
#ssh ubuntu@$prob_vm "sudo su;sudo perf stat -B  -e LLC-loads,LLC-load-misses,LLC-stores,cache-references,cache-misses,cycles,instructions 'sudo $comm_benchmark & sudo $comm_benchmark_1'" >> "test.txt"

echo "ipi test complete"




sudo git add .;sudo git commit -m 'new';sudo git push