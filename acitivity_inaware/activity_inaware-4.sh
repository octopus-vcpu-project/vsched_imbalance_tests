
prob_vm=$1
compete_vm=$2
benchmark_time=20
latency_bench="/var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 48 https://127.0.0.1:8089/test.html" 
compete_bench="./cache_thr.out"
non_cache_compete_bench="./Workloads/non-cache.o"
OUTPUT_FILE="./tests/acitivity_inaware-4$(date +%m%d%H%M).txt"
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='2' dies='1' cores='16' threads='1'/></cpu>"
idler_bench="sudo bash /home/ubuntu/idle_load_generator/idler.sh"
sudo virsh shutdown $compete_vm
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
    ssh ubuntu@$prob_vm "sudo tee /sys/kernel/debug/sched/migration_cost_ns <<< $1"
    echo "Set Migration Cost to $1" 

    echo "Set Migration Cost to $1" >> "$OUTPUT_FILE" 
}

runAllTests(){
 #  ssh ubuntu@$prob_vm "sudo killall nginx"
 #  ssh ubuntu@$prob_vm "cd /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1;sudo ./nginx_/sbin/nginx -g 'worker_processes auto;'"
 #  sleep 10
 #  ssh ubuntu@$prob_vm "sudo /var/lib/phoronix-test-suite/installed-tests/pts/nginx-3.0.1/wrk-4.2.0/wrk -d 60s -c 300 -t 8 https://127.0.0.1:8089/test.html"  >> "$OUTPUT_FILE"  
 #  ssh ubuntu@$prob_vm "sudo killall nginx"
 #  ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 32 -i native" >> "$OUTPUT_FILE"
 #  ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native" >> "$OUTPUT_FILE"
   #ssh ubuntu@$prob_vm "./vsched_tests/matmul.out 32 30" >> "$OUTPUT_FILE"
}



toggle_topological_passthrough 1


wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
setMigrationCost 1000000
ssh ubuntu@$compete_vm "sudo $compete_bench" &
#ssh ubuntu@$prob_vm "sudo $latency_bench"  >> "$OUTPUT_FILE" 
#ssh ubuntu@$prob_vm "sudo $idler_bench"  &
echo "finished warming up"



echo "Cache-Cold  tests"
echo "Cache-Cold  tests" >> $OUTPUT_FILE 

runAllTests


setMigrationCost 
runAllTests

setMigrationCost 40
runAllTests

setMigrationCost 30
runAllTests

setMigrationCost 20
runAllTests

setMigrationCost 10
runAllTests

setMigrationCost 0
runAllTests

ssh ubuntu@$compete_vm "sudo killall cache_thr.out" 
ssh ubuntu@$compete_vm "sudo $non_cache_compete_bench" &
sudo echo 3000000 > /sys/kernel/debug/sched/min_granularity_ns
echo "Cache-Hot 3ms tests"
echo "Cache-Hot 3ms tests" >> $OUTPUT_FILE 

setMigrationCost 500
runAllTests

setMigrationCost 400
runAllTests

setMigrationCost 300
runAllTests

setMigrationCost 200
runAllTests

setMigrationCost 100
runAllTests

setMigrationCost 0
runAllTests



setMigrationCost 500000
sudo git add .;sudo git commit -m 'new';sudo git push


