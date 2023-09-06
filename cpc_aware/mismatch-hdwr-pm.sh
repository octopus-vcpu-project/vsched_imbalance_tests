cpu_benchmark="sysbench --threads=8 --report-interval=3 --time=50 cpu run"

for i in {0..7};do
    sudo virsh vcpupin $prob_vm $i $((i+16))
done

taskset -c 0-15 sysbench --threads=16 --time=100000 cpu run &
taskset -c 80-95 sysbench --threads=16 --time=100000 cpu run &
echo "Finished Pinning/compeition"

ssh ubuntu@$prob_vm "sudo killall sysbench" 

#topology naive testing
OUTPUT_FILE1="./test/1-dis-hrd-pm$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd-pm$(date +%m%d%H%M).txt"
sudo taskset -c 16-19 sysbench --threads=8 --report-interval=3 --time=50 cpu run >> $OUTPUT_FILE1 &
sudo taskset -c 20-23 sysbench --threads=8 --report-interval=3 --time=50 cpu run >> $OUTPUT_FILE2 
touch $OUTPUT_FILE
echo "test complete"
