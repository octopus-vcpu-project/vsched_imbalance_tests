cpu_benchmark="sysbench --threads=4 --report-interval=3 --time=60 cpu run"

taskset -c 0-15 sysbench --threads=16 --time=100000 cpu run &
taskset -c 80-95 sysbench --threads=16 --time=100000 cpu run &
echo "Finished Pinning/compeition"

ssh ubuntu@$prob_vm "sudo killall sysbench" 

#topology naive testing
OUTPUT_FILE1="./test/1-dis-hrd-pm$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd-pm$(date +%m%d%H%M).txt"
sudo taskset -c 15-20,40,60 sysbench --threads=12 --report-interval=3 --time=50 cpu run >> $OUTPUT_FILE1 &
sudo taskset -c 15-20,40,60 sysbench --threads=12 --report-interval=3 --time=50 cpu run >> $OUTPUT_FILE2 
touch $OUTPUT_FILE
echo "test complete"
sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native