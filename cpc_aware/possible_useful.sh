prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=4 --time=10 cpu run"
compete_benchmark="sysbench --threads=52 --time=2000 cpu run"
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

#topology naive testing
OUTPUT_FILE="./test/sym-naive$(date +%m%d%H%M).txt"
for i in {0..50};do
    ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done

touch $OUTPUT_FILE
echo "test complete"
