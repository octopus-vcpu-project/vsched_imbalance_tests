\
OUTPUT_FILE="./test/unfair$(date +%m%d%H%M).txt"
OUTPUT_FILE2="./test/2-dis-hrd$(date +%m%d%H%M).txt"

prob_vm=$1
runtime=$2
period=$3
total_preempt=0
total_nonpreempts=0
num_trials=100

sudo bash ../utility/cleanon_startup.sh $prob_vm 16

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')


#sudo virsh vcpupin $prob_vm 2 2

for (( i=0; i<=31
; i++ ))
do
	sudo echo $runtime $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done
sudo echo $4 $period > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu1/cpu.max


#ssh ubuntu@$prob_vm "sudo taskset -c 2 sysbench --time=900000 --threads=1 cpu run" &
#sleep 3
#for (( i=1; i<=num_trials; i++ ))
#do
#    ssh ubuntu@$prob_vm "sudo cat /proc/check_preempt"
#    sleep 0.1
#    echo "what"
#done

#count=$(ssh ubuntu@$prob_vm "sudo dmesg | tail -n $num_trials | grep -c 'Preempt Registered'")
#preempt_ratio=$(echo "($num_trials-$count) / $num_trials" | bc -l)
#set_ratio=$(echo "($runtime+1500) / $period" | bc -l)

#echo "Number of preempts: $count"
#echo "Ratio of preempts: $preempt_ratio"
#echo "Ratio of CFS bandwith limiting: $set_ratio"
#echo "test complete"
