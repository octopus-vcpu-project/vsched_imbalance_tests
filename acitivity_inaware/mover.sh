
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


wake_and_pin_vm(){
    select_vm=$1
    sudo bash ../utility/cleanon_startup.sh $select_vm 4
    for i in {0..3};do
        sudo virsh vcpupin $select_vm $i $((i))
    done
    sleep 2
}



ssh ubuntu@$compete_vm "sudo $compete_bench" &
wake_and_pin_vm $prob_vm
wake_and_pin_vm $compete_vm
