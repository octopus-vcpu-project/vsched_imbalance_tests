prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=8 --time=1000 cpu run"
compete_benchmark="sysbench --threads=52 --time=1000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 52

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done

for i in {16..51};do
    sudo virsh vcpupin $compete_vm $i $(( i%12 ))
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &
#topology naive testing
OUTPUT_FILE="./test/asym-plc$(date +%m%d%H%M).txt"
for i in {0..500};do
    sleep 0.5
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
done
touch $OUTPUT_FILE
echo "test complete"
