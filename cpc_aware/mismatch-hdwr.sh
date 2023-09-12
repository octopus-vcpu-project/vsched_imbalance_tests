prob_vm=$1
cpu_benchmark="sysbench --threads=24 --report-interval=2 --time=50 cpu run"
#sudo bash ../utility/cleanon_startup.sh $prob_vm 32 

for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $i
done



killall sysbench
echo "Finished Pinning/compeition"

ssh ubuntu@$prob_vm "sudo killall sysbench" 

#topology naive testing
OUTPUT_FILE1="./test/newtest$(date +%m%d%H%M).txt"
sleep 1
OUTPUT_FILE2="./test/newdtest$(date +%m%d%H%M).txt"
for i in {0..2};do 
    ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE1" &
    ssh ubuntu@$prob_vm "sudo $cpu_benchmark" >> "$OUTPUT_FILE2"
    sleep 1
    echo "linebreak" >> $OUTPUT_FILE1
    echo "linebreak" >> $OUTPUT_FILE2
    echo $i
done

touch $OUTPUT_FILE
echo "test complete"
