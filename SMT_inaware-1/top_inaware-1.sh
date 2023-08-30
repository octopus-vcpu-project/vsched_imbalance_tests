prob_vm=$1
benchmark_command="sysbench --threads=16 --time=5 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 64))
done

for i in {0..41};do 
    ssh ubuntu@$prob_vm "sudo killall sysbench" &
    OUTPUT_FILE="top_inaware_naive$(date +%m%d%H%M).txt"
    ssh ubuntu@$prob_vm "cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" > "$OUTPUT_FILE"
    sleep 1
    ssh ubuntu@$prob_vm "cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" > "$OUTPUT_FILE"
    #topology naive testing
    ssh ubuntu@$prob_vm "sudo $benchmark_command" > "$OUTPUT_FILE"
done