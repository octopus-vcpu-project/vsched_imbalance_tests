

setLatency(){
    for i in $(seq $3 $4);do
        sudo echo $1 $(($2)) > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    for i in $(seq $3 $4);do
        sudo echo $(($2-$1)) $(($2)) > /sys/fs/cgroup/machine.slice/$compete_vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
    echo "Set latency to $1" 
    echo "Set latency to $1" >> "$OUTPUT_FILE" 
}
