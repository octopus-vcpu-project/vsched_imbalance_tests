
prob_vm=$1
compete_vm=$2
compete_bench="sysbench --threads=16 --time=3 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 4
sudo bash ../utility/cleanon_startup.sh $compete_vm 4

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')
compete_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
compete_vm_cgroup_title=$(sudo cat /proc/$compete_vm_pid/cgroup | awk -F "/" '{print $3}')

for i in {0..3};do
    sudo virsh vcpupin $prob_vm $i $((i))
    sudo virsh vcpupin $compete_vm $i $((i))
done

sudo echo 0 > /sys/kernel/debug/sched/wakeup_granularity_ns

OUTPUT_FILE="./data/IVHtesting-$(date +%m%d%H%M).txt"

length=${#bench_1_[@]}
ssh ubuntu@$compete_vm "sudo sysbench --threads=16 --time=900000 cpu run &"&
ssh ubuntu@$prob_vm "sudo killall a.out"

setLatency 5000 5000

setLatency(){
    for i in $(seq 0 3);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq 0 3);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}
