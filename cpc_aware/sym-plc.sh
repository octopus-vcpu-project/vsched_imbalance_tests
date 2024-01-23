prob_vm=$1
compete_vm=$2
benchmark_time=100
sudo virsh shutdown e-vm3
sleep 10
cpu_benchmark="sysbench --threads=4 --time=600 cpu run"
compete_benchmark="sysbench --threads=16 --time=200000 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 16

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done


output_thread_specific_vruntimes(){
    local threads=("$@")
    local command_str=""
    for tid in "${threads[@]}"; do
        if [ $tid -eq $sysbench_pid ]; then
            continue
        fi 
        command_str+="echo 'ThreadID: $tid'; cat /proc/$tid/sched | grep se.sum_exec_runtime; "
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}

echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall joe.out"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$prob_vm "sudo killall sysbench"
#topology naive testing
OUTPUT_FILE="./test/sym-plc$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bcc/tools/runqlen.py -C -O -T 1">> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"

ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$prob_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 10000 &  " & 
OUTPUT_FILE="./test/sym-plc-smrt$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo python /home/ubuntu/bcc/tools/runqlen.py -C -O -T 1">> "$OUTPUT_FILE" &
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" &
sleep $benchmark_time
ssh ubuntu@$prob_vm "sudo kill -s SIGINT \$(pidof python)"
sleep 4
touch $OUTPUT_FILE
echo "test complete"
