prob_vm=$1
compete_vm=$2
cpu_benchmark="sysbench --threads=4 --time=10 cpu run"
compete_benchmark="sysbench --threads=16 --time=50000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 16

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &

OUTPUT_FILE="./data/nv-sperf-$(date +%m%d%H%M).txt"
touch $OUTPUT_FILE
for i in {0..50};do
	ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done

cpu_benchmark="taskset -c 12-15 sysbench --threads=4 --time=10 cpu run"
touch $OUTPUT_FILE
OUTPUT_FILE="./data/opt-sperf-$(date +%m%d%H%M).txt"
for i in {0..50};do
        ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done

cpu_benchmark="sysbench --threads=4 --time=10 cpu run"
touch $OUTPUT_FILE
OUTPUT_FILE="./data/smrt-sperf-$(date +%m%d%H%M).txt"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 10000 &  " & 

for i in {0..50};do
        ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE"
done


echo "Test cpc_aware 1-asym-plc is complete"

echo "test complete"
