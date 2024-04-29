
prob_vm=$1
compete_vm=$2
benchmark_command="sysbench --threads=16 --time=3 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 32
sudo bash ../utility/cleanon_startup.sh $compete_vm 32
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

#s
for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $((i))
    sudo virsh vcpupin $compete_vm $i $((i))
done


setLatencyCFS(){
    echo "Set latency cfs to $1" 
    for i in {0..31};do
        sudo echo $1 $2 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
}



OUTPUT_FILE="./data/BVStesting-$(date +%m%d%H%M).txt"


setLatencyCFS 1000 2000
setLatencyCFS 4000 8000
