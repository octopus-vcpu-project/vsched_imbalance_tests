declare -a io_benchmarks
declare -a cpu_benchmarks
prob_vm=$1
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

io_benchmarks=("sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 90s -c 20 -t 16 https://127.0.0.1:8089/test.html")
io_benchmarks+=("sudo fio --filename=/test --size=1GB  --direct=1 --rw=randrw --bs=4k --ioengine=libaio --iodepth=256 --runtime=90 --numjobs=16 --time_based --group_reporting --name=iops-test-job --eta-newline=1")
cpu_benchmarks=("./vsched_tests/matmul.out 16 90")
OUTPUT_FILE="./tests/top_inaware_2_cpu$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./tests/top_inaware_2_io$(date +%m%d%H%M).txt"

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $((i+4))
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i+68))
done

test_smt_pair() {
    local cpu_bench=$1
    local io_bench=$2
    echo "first pass"
    # Adding condition for running specific commands for nginx benchmark
    if [[ $io_bench == *nginx* ]]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        sleep 5
    fi
    ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run" 
    echo "running $cpu_bench naive running $io_bench naive" >> $OUTPUT_FILE &
    echo "running $cpu_bench naive running $io_bench naive" >> $OUTPUT_FILE2 # changed $naive_bench to $io_bench
    ssh ubuntu@$prob_vm "sudo killall php"
    ssh ubuntu@$prob_vm "sudo killall sysbench" 
    ssh ubuntu@$prob_vm "$cpu_bench" >> "$OUTPUT_FILE" & 
    ssh ubuntu@$prob_vm "$io_bench" >> "$OUTPUT_FILE2"
    sleep 10
    if [[ $io_bench == *nginx* ]]; then
        ssh ubuntu@$prob_vm "sudo killall nginx"
        ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo taskset -c 16-31 ./nginx_/sbin/nginx -g 'worker_processes auto;'"
        sleep 5
    fi
    sleep 2
    ssh ubuntu@$prob_vm "sudo killall php"
    
    wait
    ssh ubuntu@$prob_vm "sudo killall nginx"
    ssh ubuntu@$prob_vm "sudo killall php"
    
}


for io_bench in "${io_benchmarks[@]}"; do
    for cpu_bench in "${cpu_benchmarks[@]}"; do
        test_smt_pair "$cpu_bench" "$io_bench"
    done
done

ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 1000 &" & 
echo "running  smart" >> $OUTPUT_FILE 
echo "running smart  smart" >> $OUTPUT_FILE2 # changed $naive_bench to $io_bench


for io_bench in "${io_benchmarks[@]}"; do
    for cpu_bench in "${cpu_benchmarks[@]}"; do
        test_smt_pair "$cpu_bench" "$io_bench"
    done
done


ssh ubuntu@$prob_vm "sudo rm -rf /home/ubuntu/tmp"