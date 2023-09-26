prob_vm=$1
comm_benchmark = "sysbench --threads=16 --time=100 cpu run"
../utility/cleanon_startup.sh prob_vm 32


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
}


for i in {0..15};do
    sudo virsh vcpupin $prob_vm $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 4))
done

ssh ubuntu@$prob_vm "sudo killall sysbench" 
toggle_topological_passthrough 0
#blind
OUTPUT_FILE="./tests/numa_unpinned$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $comm_benchmark" > "$OUTPUT_FILE" 
sleep 3
OUTPUT_FILE2="./tests/numa_pinned$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 0-16 $comm_benchmark" > "$OUTPUT_FILE2" 
sleep 3
toggle_topological_passthrough 1
#passthrough
ssh ubuntu@$prob_vm "sudo $comm_benchmark" > "$OUTPUT_FILE" 
sleep 3
ssh ubuntu@$prob_vm "sudo taskset -c 0-16 $comm_benchmark" > "$OUTPUT_FILE2" 
