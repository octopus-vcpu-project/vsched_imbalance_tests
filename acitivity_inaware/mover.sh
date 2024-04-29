
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

vm_pid=$(sudo grep pid /var/run/libvirt/qemu/$prob_vm.xml | awk -F "'" '{print $6}' | head -n 1)
vm_cgroup_title=$(sudo cat /proc/$vm_pid/cgroup | awk -F "/" '{print $3}')

setLatencyCFS(){
    for i in {0..3};do
        sudo echo $3 $4 > /sys/fs/cgroup/machine.slice/$vm_cgroup_title/libvirt/vcpu$i/cpu.max
    done
}

wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 4
    for i in {0..3};do
        sudo virsh vcpupin $select_vm $i $((i))
    done
    sleep 2
}



setLatencyCFS
wake_and_pin_vm $prob_vm