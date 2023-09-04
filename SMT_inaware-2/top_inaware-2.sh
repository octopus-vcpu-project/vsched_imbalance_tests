prob_vm = $1
cpu_benchmark = "sysbench --threads=16 --time=100 cpu run"
io_benchmark = "sysbench --threads=16 --time=100 cpu run"
sudo bash ../utility/cleanon_startup.sh prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $i $((i + 64))
done

ssh ubuntu@$prob_vm "sudo killall sysbench" &

#topology naive testing
OUTPUT_FILE="top_inaware_2_cpu_naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" > "$OUTPUT_FILE" &
OUTPUT_FILE="top_inaware_2_io_naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $io_benchmark" > "$OUTPUT_FILE"
sleep 3
#topology smart testing
OUTPUT_FILE="top_inaware_2_cpu_smart$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 0-15 $cpu_benchmark" > "$OUTPUT_FILE" &
OUTPUT_FILE="top_inaware_2_io_smart$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 16-31 $io_benchmark" > "$OUTPUT_FILE"