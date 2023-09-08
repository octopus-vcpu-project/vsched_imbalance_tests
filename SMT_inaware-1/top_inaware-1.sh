
prob_vm=$1
benchmark_command="sysbench --threads=16 --time=10000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 64))
done

OUTPUT_FILE="top_inaware_placement$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo $benchmark_command" &
for i in {0..500};do 
    sleep 0.5
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
done

echo "done"