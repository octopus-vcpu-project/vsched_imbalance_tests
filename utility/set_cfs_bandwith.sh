prob_vm=$1
set_latency=$2
total_period=$3

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

for i in {0..31};do
    sudo echo $1 $2 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
done
echo "Set latency cfs to $1" 

