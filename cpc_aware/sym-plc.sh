prob_vm=$1
compete_vm=$2
benchmark_time=200
cpu_benchmark="sysbench --threads=4 --time=600 cpu run"
compete_benchmark="sysbench --threads=16 --time=200000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 16

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall joe.out"
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
#topology naive testing
OUTPUT_FILE="./test/sym-plc$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo python3 /home/ubuntu/bpftrace/bcc/tools/runqlen.py -C">> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
ssh ubuntu@$prob_vm "sudo killall sysbench"

ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 10000 &  " & 
OUTPUT_FILE="./test/sym-plc-smrt$(date +%m%d%H%M).txt"


ssh ubuntu@$prob_vm "sudo python3 /home/ubuntu/bpftrace/bcc/tools/runqlen.py -C">> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep 4
touch $OUTPUT_FILE
echo "test complete"
