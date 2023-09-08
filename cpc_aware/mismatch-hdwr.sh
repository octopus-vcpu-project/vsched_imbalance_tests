prob_vm=$1
cpu_benchmark="sysbench --threads=32 --report-interval=3 --time=60 cpu run"
#sudo bash ../utility/cleanon_startup.sh $prob_vm 32 

for i in {0..32};do
    sudo virsh vcpupin $prob_vm $i $i
done



killall sysbench
#taskset -c 0-15 sysbench --threads=16 --time=100000 cpu run &
#taskset -c 80-95 sysbench --threads=16 --time=100000 cpu run &
echo "Finished Pinning/compeition"

ssh ubuntu@$prob_vm "sudo killall sysbench" 

#topology naive testing
OUTPUT_FILE1="./test/newtest$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/newdtest$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE1" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE2"
touch $OUTPUT_FILE
echo "test complete"
