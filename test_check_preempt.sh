
OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
runtime=$2
period=$3
total_preempt=0
total_nonpreempts=0
num_trials=400

sudo bash ../utility/cleanon_startup.sh $prob_vm 16

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')


sudo virsh vcpupin $prob_vm 2 2
sudo echo $runtime $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu2/cpu.max


ssh ubuntu@$prob_vm "sudo taskset -c 2 sysbench --time=900000 --threads=2 cpu run" &
for i in {0..$num_trials};do
    ssh ubuntu@$prob_vm "sudo echo 1 > /proc/check_preempt"
    sleep 0.1 
done
count=$(ssh ubuntu@$prob_vm "sudo dmesg | tail -n $num_trials | grep -c 'Preempt Registered'")
preempt_ratio=$(echo "$count / $num_trials" | bc -l)
set_ratio=$(echo "$runtime / ($period+$runtime)" | bc -l)

echo "Number of preempts: $count"
echo "Ratio of preempts: $preempt_ratio"
echo "Ratio of CFS bandwith limiting: $preempt_ratio"
echo "test complete"
