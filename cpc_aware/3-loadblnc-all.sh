
'This thread is to show that the linux scheduler currently does a poor job of inter-process/intra thread fairness in a VM with completely symmetrical,
competed for VCPUS. Note that the linux scheduler actually does do a fine job of intra process fairness.'


OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
runtime=$2
period=$3
cpu_benchmark="sysbench --threads=64 --time=180 cpu run"

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



ssh ubuntu@$prob_vm "sysbench --threads=64 --time=190 cpu run"  >> "$OUTPUT_FILE"  &
sleep 2
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")

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
    for tid in "${threads[@]}"; do
        if [ $tid -eq $sysbench_pid ]; then
            continue
        fi 
        command_str+="echo 'ThreadID: $tid'; cat /proc/$tid/sched | grep se.sum_exec_runtime; "
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}


declare -a thread_ids
 
new_iterator=0
for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    if [ $new_iterator -lt 5 ]; then
        thread_ids+=($tid)
    fi
    new_iterator=$((new_iterator + 1))
done

#this test is symmetric, no frills,symmetrically competed for
for i in {0..60};do
    sleep 2
    output_thread_specific_vruntimes "${thread_ids[@]}"
done

#this test is where half the cores are much weaker, assymetrically competed for.

for i in {0..15};do
    sudo echo $((runtime/3)) $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done

pin_threads_smartly "${thread_ids[@]}"

for i in {0..60};do
    sleep 2
    output_thread_specific_vruntimes "${thread_ids[@]}"
done





echo "test complete"
