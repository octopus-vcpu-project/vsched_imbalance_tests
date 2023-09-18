
prob_vm=$1
benchmark_command="sysbench --threads=16 --time=3 cpu run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32
naive_topology_string="<cpu mode='custom' match='exact' check='none'>\n<model fallback='forbid'>qemu64</model>\n</cpu>"
smart_topology_string="<cpu mode='custom' match='exact' check='none'>\n    <model fallback='forbid'>qemu64</model>\n    <topology sockets='1' dies='1' cores='16' threads='2'/></cpu>"
toggle_topological_passthrough(){
    virsh shutdown $prob_vm
    while true; do
        vm_state=$(virsh domstate "$prob_vm")
        echo $vm_state
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

for i in {0..31};do
    sudo virsh vcpupin $prob_vm $i $(((i/2)+(i%2)*80))
    echo "virsh vcpu pinned $i $(((i/2)+(i%2)*80))" 
done


OUTPUT_FILE="./tests/top_plc_naive$(date +%m%d%H%M).txt"
toggle_topological_passthrough 0



for i in {0..40};do 
    ssh ubuntu@$prob_vm "sudo $benchmark_command" &
    sleep 2
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
    sleep 2
done

toggle_topological_passthrough 1

OUTPUT_FILE="./tests/top_plc_smart$(date +%m%d%H%M).txt"
for i in {0..40};do 
    ssh ubuntu@$prob_vm "sudo $benchmark_command" &
    sleep 2
    ssh ubuntu@$prob_vm "sudo cat /sys/kernel/debug/sched/debug | grep -E 'cpu#|>R '" >> "$OUTPUT_FILE"
    sleep 2
done
