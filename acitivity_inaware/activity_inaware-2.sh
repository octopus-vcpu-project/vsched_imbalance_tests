
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./tests/acitivity_inaware-2$(date +%m%d%H%M).txt"

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i + 20))
    done

    for i in {16..31};do
        sudo virsh vcpupin $select_vm $i $((i + 24))
    done
    sleep 2
}

runLatencyTest(){
    latency_option=$1
    echo "Running Latency benchmark $1" 
    echo "Running Latency benchmark $1" >> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$1;time sudo bash run.sh"  >> "$OUTPUT_FILE" 2>&1
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "$OUTPUT_FILE" 2>&1
}

setLatency(){
    set_latency=$1
    sudo echo $1 > /sys/kernel/debug/sched/min_granularity_ns
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}

toggle_topological_passthrough(){
    naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
    smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
    virsh shutdown $prob_vm
    while true; do
        vm_state=$(virsh domstate "$prob_vm")
        if [ "$vm_state" != "running" ]; then
            echo "VM is shutdown"
            break
        else
            echo "Waiting for VM to shutdown"
            sleep 3 
        fi
    done
    virsh dumpxml $prob_vm > /tmp/$prob_vm.xml
    if [ $1 -eq 1 ]; then
        sed -i "/<cpu /,/<\/cpu>/c\\$smart_topology_string" /tmp/$prob_vm.xml
    else
        sed -i "/<cpu /,/<\/cpu>/c\\$naive_topology_string" /tmp/$prob_vm.xml
    fi
    virsh define /tmp/$prob_vm.xml
    sudo bash ../utility/cleanon_startup.sh $prob_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done

    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 24))
    done
    echo "Pinning Complete"
    ssh ubuntu@$prob_vm "sudo killall mysqld"
} 

runAllTests(){
    runLatencyTest "img-dnn"
    runLatencyTest "moses"
    runLatencyTest "masstree"
    runLatencyTest "silo"
    runLatencyTest "shore"
    runLatencyTest "specjbb"
    runLatencyTest "sphinx"
    runLatencyTest "xapian"
}


toggle_topological_passthrough 0
wake_and_pin_vm $compete_vm
#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')

ssh ubuntu@$prob_vm "sudo killall a.out"
ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
ssh ubuntu@$prob_vm "$idler_bench" &
sleep 10

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


