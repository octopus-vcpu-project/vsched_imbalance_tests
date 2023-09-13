
OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
runtime=$2
period=$3
cpu_benchmark="sysbench --threads=64 --report-interval=3 --time=120 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
#PIN VCPUS and limit CPU usage using CGROUP

ssh ubuntu@$prob_vm "sudo killall sysbench" 
for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo echo $runtime $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done

for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
    sudo echo $((runtime/2)) $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done

output_thread_specific_vruntimes(){
    local threads=("$@")
    local command_str=""
    for tid in "${threads[@]}"; do
        command_str+="echo 'ThreadID: $tid'; cat /proc/$tid/sched | grep se.vruntime; "
    done
    ssh ubuntu@"$prob_vm" "$command_str" >> "$OUTPUT_FILE"
}


ssh ubuntu@$prob_vm "sysbench --threads=64 --time=50 cpu run" &
sleep 2
sysbench_pid=$(ssh ubuntu@$prob_vm "pidof sysbench")

declare -a thread_ids

for tid in $(ssh ubuntu@$prob_vm "ls /proc/$sysbench_pid/task");do
    thread_ids+=($tid)
done

for i in {0..20};do
    sleep 2
    output_thread_specific_vruntimes "${thread_ids[@]}"
done

echo "test complete"
