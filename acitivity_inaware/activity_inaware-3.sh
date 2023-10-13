
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="sysbench --threads=32 --time=30 cpu run"
compete_bench="sysbench --threads=32 --time=3000000 cpu run"
OUTPUT_FILE="./tests/acitivity_inaware-2$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..31};do
        sudo virsh vcpupin $select_vm $i $i
    done
    sleep 2
}

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
ssh ubuntu@$compete_vm "sudo killall sysbench"
ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo $compete_bench"&
ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

for i in {0..31};do
    sudo echo 5000 10000 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    sudo echo 5000 10000 > /sys/fs/cgroup/machine.slice/$c_vm_cgroup_title/libvirt/vcpu$i/cpu.max
done

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

for i in {0..31};do
    sudo echo 50000 100000 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    sudo echo 50000 100000 > /sys/fs/cgroup/machine.slice/$c_vm_cgroup_title/libvirt/vcpu$i/cpu.max

done

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 

for i in {0..31};do
    sudo echo 500000 1000000 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    sudo echo 500000 1000000 > /sys/fs/cgroup/machine.slice/$c_vm_cgroup_title/libvirt/vcpu$i/cpu.max

done

ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 




sudo git add .;sudo git commit -m 'new';sudo git push


