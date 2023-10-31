
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 48 https://127.0.0.1:8089/test.html" 
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-4$(date +%m%d%H%M).txt"
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"


toggle_topological_passthrough(){
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

setMigrationCost(){
    sudo echo $1 > /sys/kernel/debug/sched/migration_cost_ns
    echo "Set Migration Cost to $1" 
    echo "Set Migration Cost to $1" >> "$OUTPUT_FILE" 
}

runAllTests(){
   ssh ubuntu@$prob_vm "sudo killall nginx"
   ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
   sleep 10
   ssh ubuntu@$prob_vm "sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 16 https://127.0.0.1:8089/test.html"  >> "$OUTPUT_FILE"  
   ssh ubuntu@$prob_vm "sudo killall nginx"
   #ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 32 -i native" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "./vsched_tests/matmul.out 32 30" >> "$OUTPUT_FILE"
}



toggle_topological_passthrough 0


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
ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 
echo "finished warming up"



sudo echo 32000000 > /sys/kernel/debug/sched/min_granularity_ns
echo "Cache-Hot 32ms tests"
echo "Cache-Hot 32ms tests" >> $OUTPUT_FILE 
setMigrationCost 1000000
runAllTests

setMigrationCost 900000
runAllTests

setMigrationCost 800000
runAllTests

setMigrationCost 700000
runAllTests

setMigrationCost 600000
runAllTests

setMigrationCost 500000
runAllTests

setMigrationCost 400000
runAllTests

setMigrationCost 300000
runAllTests

setMigrationCost 200000
runAllTests

setMigrationCost 100000
runAllTests

setMigrationCost 0
runAllTests

sudo echo 1000000 > /sys/kernel/debug/sched/min_granularity_ns
echo "Cache-Cold 3ms tests"
echo "Cache-Cold 3ms tests" >> $OUTPUT_FILE 

setMigrationCost 1000000
runAllTests

setMigrationCost 900000
runAllTests

setMigrationCost 800000
runAllTests

setMigrationCost 700000
runAllTests

setMigrationCost 600000
runAllTests

setMigrationCost 500000
runAllTests



setMigrationCost 400000
runAllTests

setMigrationCost 300000
runAllTests

setMigrationCost 200000
runAllTests

setMigrationCost 100000
runAllTests

setMigrationCost 0
runAllTests

setMigrationCost 500000
sudo git add .;sudo git commit -m 'new';sudo git push


