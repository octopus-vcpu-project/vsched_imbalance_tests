
'This thread is to show that the linux scheduler currently does a poor job of inter-process/intra thread fairness in a VM with completely symmetrical,
competed for VCPUS. Note that the linux scheduler actually does do a fine job of intra process fairness.'


OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
compete_vm=$2
compete_vm1=$3
cpu_benchmark="sysbench --threads=30 --time=150 cpu run"
compete_benchmark="sysbench --threads=32 --time=10000 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 16
sudo bash ../utility/cleanon_startup.sh $compete_vm 32
sudo bash ../utility/cleanon_startup.sh $compete_vm1 16
#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
#PIN VCPUS and limit CPU usage using CGROUP

ssh ubuntu@$prob_vm "sudo killall sysbench" 
for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $((i + 20))
done

for i in {0..31};do
    sudo virsh vcpupin $compete_vm $i $(((i%16) + 20))
done

for i in {0..15};do
    sudo virsh vcpupin $compete_vm1 $i $(((i%8) + 20))
done

ssh ubuntu@$compete_vm "sudo $compete_benchmark" &
ssh ubuntu@$compete_vm1 "sudo $compete_benchmark" &
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
        if [ $iterator -lt 32 ]; then
            pin_location=$((iterator % 16))
        fi
        command_str+="taskset -cp $pin_location $tid;"
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



wipe_clean $prob_vm
ssh ubuntu@$prob_vm "$cpu_benchmark"    &
sleep 1
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")
declare -a thread_ids
new_iterator=0
for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    thread_ids+=($tid)
    new_iterator=$((new_iterator + 1))
done
OUTPUT_FILE="./test/unf-asym-nve-$(date +%m%d%H%M).txt"
for i in {0..35};do
    output_thread_specific_vruntimes "${thread_ids[@]}"
    sleep 4
done

echo "unf-asym-nve test complete"

wipe_clean $prob_vm
<<comm
ssh ubuntu@$prob_vm "$cpu_benchmark"    &
sleep 1
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")
declare -a mread_ids
for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    mread_ids+=($tid)
    new_iterator=$((new_iterator + 1))
done
OUTPUT_FILE="./test/unf-asym-pin-$(date +%m%d%H%M).txt"

pin_threads_smartly "${mread_ids[@]}"
for i in {0..25};do
    sleep 3
    output_thread_specific_vruntimes "${mread_ids[@]}"
done
echo "unf-asym-pin test complete"
comm

OUTPUT_FILE="./test/unf-asym-smrt-$(date +%m%d%H%M).txt"
wipe_clean $prob_vm
ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/joe.out -v -i 500 -s 15000 &  " & 

ssh ubuntu@$prob_vm "$cpu_benchmark"    &
sleep 1
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")
declare -a smrt_thread_ids
new_iterator=0
for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    smrt_thread_ids+=($tid)
    new_iterator=$((new_iterator + 1))
done
for i in {0..40};do
    output_thread_specific_vruntimes "${smrt_thread_ids[@]}"
    sleep 3
done
wipe_clean $prob_vm


echo "test complete"
