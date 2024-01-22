prob_vm=$1 
compete_vm=$2 
cpu_benchmark="sysbench --threads=4 --time=60 cpu run" 
compete_benchmark="sysbench --threads=16 --time=1000000 cpu run" 
cpu_benchmark_pinned="taskset -c 12-15 sysbench --threads=4 --time=10 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 16 $compete_vm 16

output_thread_specific_migrations(){
    local threads=("$@")
    local command_str=""
    for tid in "${threads[@]}"; do
        if [ $tid -eq $sysbench_pid ]; then
            continue
        fi 
        command_str+="echo 'ThreadID: $tid'; cat /proc/$tid/sched | grep se.nr_migrations; "
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo virsh vcpupin $compete_vm $i $i
done


echo "Finished Pinning"

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo $compete_benchmark" &

#topology naive testing
OUTPUT_FILE="./test/bym-naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" 
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")

for i in {0..25};do
    sleep 2
    output_thread_specific_migrations "${thread_ids[@]}"
done
touch $OUTPUT_FILE

OUTPUT_FILE="./test/bym-opt$(date +%m%d%H%M).txt"
for i in {0..25};do
    output_thread_specific_migrations "${thread_ids[@]}"
done
touch $OUTPUT_FILE

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$compete_vm "sudo killall joe.out"

ssh ubuntu@$prob_vm "sudo $compete_benchmark" &
#ssh ubuntu@$compete_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$compete_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 10000 &  " & 

OUTPUT_FILE="./test/bym-smrt$(date +%m%d%H%M).txt"
for i in {0..25};do
    output_thread_specific_migrations "${thread_ids[@]}"
done

touch $OUTPUT_FILE

#topology naive testing
echo "test complete"


