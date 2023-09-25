declare -a io_benchmarks
declare -a cpu_benchmarks
prob_vm=$1
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
scp -r ./test-profiles/matmul.c ubuntu@$prob_vm:/tmp/
ssh ubuntu@$prob_vm "g++ /tmp/matmul.c /tmp/ma.out" 
io_benchmarks=("${io_benchmarks[@]}" "/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 90s -c 100 -t 16 https://127.0.0.1:8089/test.html")
io_benchmarks=("${io_benchmarks[@]}" "fio --filename=/test --size=1GB --ioengine=libaio --iodepth=256 --runtime=90 --numjobs=16 --time_based --group_reporting --name=iops-test-job --eta-newline=1")
cpu_benchmarks=("${cpu_benchmarks[@]}" "sysbench --threads=16 --time=90 cpu run ")
cpu_benchmarks=("${cpu_benchmarks[@]}" "a.out")

OUTPUT_FILE="./tests/top_inaware_2_cpu$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/top_inaware_2_io$(date +%m%d%H%M).txt"


test_smt_pair(){
    local cpu_bench=$1
    local io_bench=$2
    echo "running $cpu_bench naive">> $OUTPUT_FILE 
    echo "running $naive_bench naive">> $OUTPUT_FILE2
    ssh ubuntu@$prob_vm "sudo killall sysbench" 
    ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run" 
    #topology naive testing
    ssh ubuntu@$prob_vm "sudo echo '' > /home/ubuntu/tmp/waitingprocesses.tmp" 

    ssh ubuntu@$prob_vm "sudo $cpu_bench" >> "$OUTPUT_FILE" & 
    ssh ubuntu@$prob_vm "sudo $io_bench" >> "$OUTPUT_FILE2" 
    wait
    sleep 2
    echo "running $cpu_bench smart">> $OUTPUT_FILE 
    echo "running $naive_bench smart">> $OUTPUT_FILE2
    #topology smart testing
    ssh ubuntu@$prob_vm "sudo echo '' > /home/ubuntu/tmp/waitingprocesses.tmp" 
    ssh ubuntu@$prob_vm "sudo taskset -c 0-15 phoronix-test-suite default-benchmark $cpu_bench" >> "$OUTPUT_FILE" &
    ssh ubuntu@$prob_vm "sudo taskset -c 16-31 phoronix-test-suite default-benchmark $io_bench" >> "$OUTPUT_FILE2"
    wait
}



test_smt_pair 

for io_bench in "${io_benchmarks[@]}"; do
    for cpu_bench in "${cpu_benchmarks[@]}"; do
        test_smt_pair $cpu_bench $io_bench
    done
done
ssh ubuntu@$prob_vm "sudo rm -rf /home/ubuntu/tmp"