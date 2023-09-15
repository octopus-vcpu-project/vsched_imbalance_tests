
prob_vm=$1
benchmark_command="sysbench --threads=16 --time=3 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $((i//2))
    echo "virsh vcpu pinned $i $((i//2))" 
done


OUTPUT_FILE="./tests/top_inaware_placement$(date +%m%d%H%M).txt"

for i in {0..40};do 
    ssh ubuntu@$prob_vm "sudo $benchmark_command" &
    sleep 2
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
    sleep 2
done