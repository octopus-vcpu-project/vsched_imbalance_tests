
'This thread is to show that the linux scheduler currently does a poor job of inter-process/intra thread fairness in a VM with completely symmetrical,
competed for VCPUS. Note that the linux scheduler actually does do a fine job of intra process fairness.'


OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
runtime=$2
period=$3
cpu_benchmark="sysbench --threads=64 --time=40 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 32
#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
#PIN VCPUS and limit CPU usage using CGROUP

ssh ubuntu@$prob_vm "sudo killall sysbench" 
for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 32))
    sudo echo $runtime $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done


wipe_clean(){
    local local_prob_vm=$1
    ssh ubuntu@"$local_prob_vm" "sudo killall sysbench"
    ssh ubuntu@"$local_prob_vm" "sudo killall joe.out"
}



pin_threads_smartly(){
    local threads=("$@")
    local command_str=""
    local iterator=0
    local pin_location=0
    for tid in "${threads[@]}"; do
        if [ $tid -eq $sysbench_pid ]; then
            continue
        fi 
        if [ $iterator -lt 16 ]; then
            pin_location=$iterator
        elif [ $iterator -lt 64 ]; then
            pin_location=$((iterator % 16 + 16))
        fi
        command_str+="taskset -cp $pin_location $tid; "
        iterator=$((iterator + 1))
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}

output_thread_specific_vruntimes(){
    local threads=("$@")
    local command_str=""
    local dew_iterator=0
    for tid in "${threads[@]}"; do
        if [ $tid -eq $sysbench_pid ]; then
            continue
        fi 
        dew_iterator=$((dew_iterator + 1))
        command_str+="echo 'ThreadID: $tid'; cat /proc/$tid/sched | grep se.sum_exec_runtime; "
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}





#this test is symmetric, no frills,symmetrically competed for
<<comm
echo "unf-sym-nve test started"
OUTPUT_FILE="./test/unf-sym-nve-$(date +%m%d%H%M).txt"
for i in {0..30};do
    sleep 2
    output_thread_specific_vruntimes "${thread_ids[@]}"
done
echo "unf-sym-nve test complete"
comm
#this test is where half the cores are much weaker, assymetrically competed for.

for i in {0..15};do
    sudo echo $((runtime/3)) $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done
OUTPUT_FILE="./test/unf-asym-nve-$(date +%m%d%H%M).txt"

wipe_clean $prob_vm
ssh ubuntu@$prob_vm "$cpu_benchmark"    &
sleep 2
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/perf/perf stat -a --per-thread -o /home/ubuntu/testout.txt -e task-clock -p $sysbench_pid -I 1000"  &

ssh ubuntu@$prob_vm "sudo kill -s SIGINT $(pidof perf)"
scp ubuntu@$prob_vm:/home/ubuntu/testout.txt ./$OUTPUT_FILE

echo "unf-asym-nve test complete"
wipe_clean $prob_vm
OUTPUT_FILE="./test/unf-asym-pin-$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "$cpu_benchmark" &   
sleep 2
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/perf/perf stat -a --per-thread -o testout.txt -e task-clock -p $sysbench_pid -I 1000"  &
declare -a mread_ids
for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    mread_ids+=($tid)
    new_iterator=$((new_iterator + 1))
done
pin_threads_smartly "${mread_ids[@]}"
echo "Finished pinning!"
sleep 38
ssh ubuntu@$prob_vm "sudo kill -s SIGINT $(pidof perf)"
scp ubuntu@$prob_vm:/home/ubuntu/testout.txt ./$OUTPUT_FILE

OUTPUT_FILE="./test/unf-asym-smrt-$(date +%m%d%H%M).txt"
wipe_clean $prob_vm
ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 15000 &  " & 
ssh ubuntu@$prob_vm "$cpu_benchmark"   &
sleep 2
ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/perf/perf stat -a --per-thread -o testout.txt -e task-clock -p $sysbench_pid -I 1000" &
sleep 40
ssh ubuntu@$prob_vm "sudo kill -s SIGINT $(pidof perf)"
scp ubuntu@$prob_vm:/home/ubuntu/testout.txt ./$OUTPUT_FILE

<<comm
for i in {0..30};do
    sleep 3
    output_thread_specific_vruntimes "${smrt_thread_ids[@]}"
done
comm
wipe_clean $prob_vm


echo "test complete"
