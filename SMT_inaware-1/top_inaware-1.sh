prob_vm = $1
benchmark_command = "sysbench --threads=16 --time=100 cpu run"
../utility/cleanon_startup.sh prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $i $((i + 64))
done

ssh ubuntu@$prob_vm "sudo killall sysbench" &

#topology naive testing
OUTPUT_FILE="top_inaware_naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $benchmark_command" > "$OUTPUT_FILE"

#topology smart testing
OUTPUT_FILE="top_inaware_smart$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 0-15 $benchmark_command" > "$OUTPUT_FILE"