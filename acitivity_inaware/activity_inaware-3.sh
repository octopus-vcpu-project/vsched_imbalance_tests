
prob_vm=$1
compete_vm=$2
benchmark_time=20
cache_bench="sysbench --threads=32 --time=30 cpu run"
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-3$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..31};do
        sudo virsh vcpupin $select_vm $i $i
    done
    sleep 2
}

setLatency(){
    set_latency=$1
    sudo echo $1 > /sys/kernel/debug/sched/min_granularity_ns
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}


runAllTests(){
    ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run"  >> "$OUTPUT_FILE" 2>&1
    ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run"  >> "$OUTPUT_FILE" 2>&1
    ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run"  >> "$OUTPUT_FILE" 2>&1
    ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run"  >> "$OUTPUT_FILE" 2>&1
    ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run"  >> "$OUTPUT_FILE" 2>&1
}

wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
ssh ubuntu@$compete_vm "sudo killall ./cache_thr.out"

ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall a.out" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
ssh ubuntu@$prob_vm "sudo $cache_bench"  >> "$OUTPUT_FILE" 
echo "finished warming up"



setLatency 32000000
runAllTests

setLatency 16000000
runAllTests

setLatency 8000000
runAllTests

setLatency 4000000
runAllTests

setLatency 2000000
runAllTests

setLatency 3000000
runAllTests


sudo git add .;sudo git commit -m 'new';sudo git push


