bench_1_=("sysbench --threads=32 --time=60 cpu run")


prob_vm="e-vm3"
compete_vm_1="e-vm1"
compete_vm_2="vsched-1"
OUTPUT_FILE="./tests/output$(date +%m%d%H%M)naive.txt"
OUTPUT_FILE_PROBE="./tests/output$(date +%m%d%H%M)smrt.txt"
windup_compete_vms(){
    sudo bash ../utility/cleanon_startup.sh $compete_vm_2 8
    sudo bash ../utility/cleanon_startup.sh $compete_vm_1 32
    for i in {0..15};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 20))
    done
    for i in {16..31};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 40 ))
    done
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $i
    done
    ssh ubuntu@$compete_vm_1 "sudo sysbench --threads=32 --time=10000000 cpu run"&
    ssh ubuntu@$compete_vm_2 "sudo sysbench --threads=32 --time=10000000 cpu run"&
}

reset_prob_vm(){
    virsh shutdown $prob_vm
    sleep 50
    sudo bash ../utility/cleanon_startup.sh $prob_vm 32
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done
    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 40 ))
    done
    ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
}


activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 10" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
    ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/cpu_prober.out -i 20 -s 2000 &  " & 
    sleep 10
}


set_normal_mode(){
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $i
    done
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done
    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 40 ))
    done
}

set_interference_mode(){
    for i in {0..15};do
        sudo virsh vcpupin $prob_vm $i $(( (i%10) + 20))
    done
    for i in {16..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 40 ))
    done

    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $((40))
    done
}


reset_prob_vm
windup_compete_vms
length=${#bench_1_[@]}
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    (
        while true; do
            set_normal_mode
            sleep 20
            set_interference_mode
            sleep 20
        done
    ) &
    mode_pid=$!
    ssh ubuntu@$prob_vm "sudo $bench_1">>"${OUTPUT_FILE}_$i"
done
activate_vprobers
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
length=${#bench_1_[@]}
for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    (
        while true; do
            set_normal_mode
            sleep 20
            set_interference_mode
            sleep 20
        done
    ) &
    mode_pid=$!
    ssh ubuntu@$prob_vm "sudo $bench_1">>"${OUTPUT_FILE_PROBE}_$i"
done