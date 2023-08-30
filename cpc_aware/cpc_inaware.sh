prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=8 --time=60 cpu run"
compete_benchmark="sysbench --threads=16 --time=10000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 16

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
#topology naive testing
OUTPUT_FILE="/test/cpc_inaware$(date +%m%d%H%M).txt"
#ssh ubuntu@$prob_vm "sudo $cpu_benchmark" > "$OUTPUT_FILE" &
touch $OUTPUT_FILE
ssh ubuntu@$prob_vm "sudo runqlen.py -c -T 1 60" > "$OUTPUT_FILE"
echo "test complete"
