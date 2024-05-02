
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="cd /home/ubuntu/Workloads/tailbench-v0.9/img-dnn;time sudo bash run.sh"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
compete_bench="sudo sysbench --threads=32 --time=1000000 cpu run"
get_lat_val="cd /home/ubuntu/Workloads/tailbench-v0.9/utilities;sudo python parselats-1.py ../img-dnn/lats.bin"
OUTPUT_FILE="./data/obj-latency-noidle$(date +%m%d%H%M).txt"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
sleep 2
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

compete_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
compete_vm_cgroup_title=$(sudo cat /proc/$compete_vm_pid/cgroup | awk -F "/" '{print $3}')

#PIN VCPUS and limit CPU usage using CGROUP
#QPS should be low as to avoid competitoin among queues 
ssh ubuntu@$prob_vm "sudo killall sysbench" 



wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 32
    for i in $(seq 0 15);do
        sudo virsh vcpupin $select_vm $i $((i + 20))
    done

    for i in $(seq 16 31);do
        sudo virsh vcpupin $select_vm $i $((i + 24))
    done
    sleep 2
}

runLatencyTest(){
    latency_option=$1
    echo "Running Latency benchmark $1" 
    echo "Running Latency benchmark $1" >> "$OUTPUT_FILE" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/$1;time sudo bash run.sh" 
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "$OUTPUT_FILE" 2>&1
}

setLatency(){
#    sudo echo 1000000 > /sys/kernel/debug/sched/min_granularity_ns
    for i in $(seq 0 31);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq 0 31);do
        sudo echo $1 $(($1 * 2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
#    sudo echo 1000000 > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/cpu.weight
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}


runAllTests(){
    runLatencyTest "img-dnn"
    #runLatencyTest "moses"
    #runLatencyTest "masstree"
    #runLatencyTest "silo"
    #runLatencyTest "shore"
    #runLatencyTest "specjbb"
    #runLatencyTest "sphinx"
    #runLatencyTest "xapian"
}

runTestBlock(){

    setLatency 32000
    runAllTests
    #runAllTests
    #runAllTests

    setLatency 16000
    runAllTests
    #runAllTests
    #runAllTests


    setLatency 8000
    runAllTests
    #runAllTests
    #runAllTests


    setLatency 4000
    runAllTests
    #runAllTests
    #runAllTests


    setLatency 2000
    runAllTests
    #runAllTests
    #runAllTests
}


wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title

sudo echo 40000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 40000000 > /sys/kernel/debug/sched/wakeup_granularity_ns

ssh ubuntu@$prob_vm "sudo killall a.out"
ssh ubuntu@$compete_vm "sudo killall sysbench" 
ssh ubuntu@$compete_vm "sudo $compete_bench" &
sleep 10

runTestBlock
echo "idler added" >> "$OUTPUT_FILE"
ssh ubuntu@$prob_vm "$idler_bench" &
sleep 10
runTestBlock

setLatency 3000000
sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
sudo echo 4000000 > /sys/kernel/debug/sched/wakeup_granularity_ns
sudo echo 100 > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/cpu.weight
sudo git add .;sudo git commit -m 'new';sudo git push


