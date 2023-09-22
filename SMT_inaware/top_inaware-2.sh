declare -a io_benchmarks
declare -a cpu_benchmarks
prob_vm=$1
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
io_benchmarks=("${io_benchmarks[@]}" "nginx-smt")
io_benchmarks=("${io_benchmarks[@]}" "fio-smt")
cpu_benchmarks=("${cpu_benchmarks[@]}" "sysbench-smt")
cpu_benchmarks=("${cpu_benchmarks[@]}" "stressng-smt")

OUTPUT_FILE="./tests/top_inaware_2_cpu$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/top_inaware_2_io$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "mkdir /home/ubuntu/tmp/"
ssh ubuntu@$prob_vm "touch /home/ubuntu/tmp/waitingprocesses.tmp"
setup_phoronix_benchmark(){
    local bench=$1
    scp -r ./test-profiles/$bench ubuntu@$prob_vm:/tmp/
    ssh ubuntu@$prob_vm "sudo rm -rf /var/lib/phoronix-test-suite/test-profiles/local/$bench" 
    ssh ubuntu@$prob_vm "sudo mv /tmp/$bench /var/lib/phoronix-test-suite/test-profiles/local" 
}

test_smt_pair(){
    local cpu_bench=$1
    local io_bench=$2
    echo "running $cpu_bench naive">> $OUTPUT_FILE 
    echo "running $naive_bench naive">> $OUTPUT_FILE2
    ssh ubuntu@$prob_vm "sudo killall sysbench" 
    ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run" 
    #topology naive testing
    ssh ubuntu@$prob_vm "sudo echo '' > /home/ubuntu/tmp/waitingprocesses.tmp" 

    ssh ubuntu@$prob_vm "sudo phoronix-test-suite default-benchmark $cpu_bench" >> "$OUTPUT_FILE" & 
    ssh ubuntu@$prob_vm "sudo phoronix-test-suite default-benchmark $io_bench" >> "$OUTPUT_FILE2" 
    sleep 2
    echo "running $cpu_bench smart">> $OUTPUT_FILE 
    echo "running $naive_bench smart">> $OUTPUT_FILE2
    #topology smart testing
    ssh ubuntu@$prob_vm "sudo echo '' > /home/ubuntu/tmp/waitingprocesses.tmp" 
    ssh ubuntu@$prob_vm "sudo taskset -c 0-15 phoronix-test-suite default-benchmark $cpu_bench" >> "$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo taskset -c 16-31 phoronix-test-suite default-benchmark $io_bench" >> "$OUTPUT_FILE2"  
}


for bench in "${io_benchmarks[@]}"; do
    setup_phoronix_benchmark $bench
done


for bench in "${cpu_benchmarks[@]}"; do
    setup_phoronix_benchmark $bench
done

for i in {0..15};do
    sudo virsh vcpupin $prob_vm  $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 64))
done

for io_bench in "${io_benchmarks[@]}"; do
    for cpu_bench in "${cpu_benchmarks[@]}"; do
        test_smt_pair $cpu_bench $io_bench
    done
done
ssh ubuntu@$prob_vm "sudo rm -rf /home/ubuntu/tmp"