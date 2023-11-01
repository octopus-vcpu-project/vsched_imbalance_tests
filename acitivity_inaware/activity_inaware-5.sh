
prob_vm=$1
compete_vm=$2
benchmark_time=20
jumper_bench="sudo sysbench --threads=1 --time=30 cpu run" 
compete_bench="./cache_thr.out"
OUTPUT_FILE="./tests/acitivity_inaware-5$(date +%m%d%H%M).txt"
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
    sudo bash ../utility/cleanon_startup.sh $prob_vm 8
    for i in {0..7};do
        sudo virsh vcpupin $prob_vm $i $((i))
    done

    echo "Pinning Complete"
   ssh ubuntu@$prob_vm "sudo killall mysqld"
} 

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 7
    for i in {0..15};do
        sudo virsh vcpupin $select_vm $i $((i))
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
   ssh ubuntu@$prob_vm "sysbench --threads=32 --time=30 cpu run" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 32 -i native" >> "$OUTPUT_FILE"
   ssh ubuntu@$prob_vm "sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native" >> "$OUTPUT_FILE"
   #ssh ubuntu@$prob_vm "./vsched_tests/matmul.out 32 30" >> "$OUTPUT_FILE"
}



wake_and_pin_vm $prob_vm

#Fetch VM PID and use that to fetch Cgroup title
vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

c_vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$compete_vm.xml | awk -F "'" '{print $6}' | head -n 1)
c_vm_cgroup_title=$(sudo cat /proc/$c_vm_pid/cgroup | awk -F "/" '{print $3}')
ssh ubuntu@$compete_vm "sudo killall ./cache_thr.out"
setLatencyCFS(){
    set_latency=$1
    total_period=$2
    ssh ubuntu@$prob_vm "sudo killall sysbench" 
    for i in {0..31};do
        sudo echo $1 $2 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency cfs to $1" 
    echo "Set latency cfs to $1" >> "$OUTPUT_FILE" 
}


setLatencyCFS 4000000 8000000

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo killall a.out" 
ssh ubuntu@$prob_vm "sudo $jumper_bench"  >> "$OUTPUT_FILE" 


num_cores=$(nproc)

# Initialize variable i to 0
i=0

# Start sysbench CPU test in the background
sysbench cpu --threads=1 run & >> "$OUTPUT_FILE" 
sysbench_pid=$!

# Loop to change the CPU core for sysbench every 4 milliseconds
while [ -e /proc/$sysbench_pid ]; do
  # Compute the CPU core to set
  target_core=$(( (i + 1) % num_cores ))

  # Use taskset to set the CPU affinity for sysbench
  taskset -cp $target_core $sysbench_pid > /dev/null

  # Increment i
  i=$((i + 1))

  # Sleep for 4 milliseconds
  sleep 0.004
done


sudo git add .;sudo git commit -m 'new';sudo git push


