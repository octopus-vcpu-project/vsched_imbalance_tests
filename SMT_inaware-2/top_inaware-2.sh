prob_vm=$1
cpu_benchmark="sysbench --threads=16 --time=100 cpu run"
io_benchmark="sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=100 fileio run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $prob_vm  $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 64))
done

ssh ubuntu@$prob_vm "sudo killall sysbench" 

#topology naive testing
OUTPUT_FILE="top_inaware_2_cpu_naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $cpu_benchmark;sudo $io_benchmark" >> "$OUTPUT_FILE" 
sleep 10
#topology smart testing
OUTPUT_FILE2="top_inaware_2_cpu_smart$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 0-15 $cpu_benchmark;sudo taskset -c 16-31 $io_benchmark" >> "$OUTPUT_FILE2" 
