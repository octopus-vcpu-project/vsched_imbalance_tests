

#bench_1_=("sudo sysbench --threads=16 --time=40 cpu run")
#bench_1_=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p dedup -n 32 -i native")
#bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p streamcluster -n 32 -i native")
#bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p bodytrack -n 32 -i native")
bench_1_=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p facesim -n 32 -i native")
#bench_1_=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -a run -p canneal -n 32 -i native")

#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/img-dnn;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/moses;time sudo bash run.sh")
#bench_1_=("cd /home/ubuntu/Workloads/Tailbench/tailbench/masstree;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/silo;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/shore;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/specjbb;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/sphinx;time sudo bash run.sh")
#bench_1_+=("cd /home/ubuntu/Workloads/Tailbench/tailbench/xapian;time sudo bash run.sh")

prob_vm="e-vm3"
compete_vm_1="e-vm1"
compete_vm_2="vsched-1"
OUTPUT_FILE="./tests/output$(date +%m%d%H%M)naive.txt"
OUTPUT_FILE_PROBE="./tests/output$(date +%m%d%H%M)smrt.txt"


windup_compete_vms(){
    sudo bash ../utility/cleanon_startup.sh $compete_vm_2 8
    sudo bash ../utility/cleanon_startup.sh $compete_vm_1 32
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 20))
    done
    for i in {8..15};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 92))
    done
    for i in {16..23};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 24 ))
    done
    for i in {24..31};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 96 ))
    done
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $i
    done
    ssh ubuntu@$compete_vm_1 "sudo sysbench --threads=32 --time=10000000 cpu run"&
    ssh ubuntu@$compete_vm_2 "sudo sysbench --threads=32 --time=10000000 cpu run"&
}



runLatencyTest(){
    latency_option=$1
    echo "Running Latency benchmark $1" 
    echo "Running Latency benchmark $1" >> "${OUTPUT_FILE}_$1"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "${OUTPUT_FILE}_$1" 2>&1
}



runLatencyTestSMRT(){
    latency_option=$1
    echo "Running Latency benchmark $1" 
    echo "Running Latency benchmark $1" >> "${OUTPUT_FILE_PROBE}_$1"
    ssh ubuntu@$prob_vm "cd /home/ubuntu/Workloads/Tailbench/tailbench/utilities;sudo python parselats-1.py ../$1/lats.bin"  >> "${OUTPUT_FILE_PROBE}_$1" 2>&1
}

getLatencyResults(){
#    runLatencyTest "img-dnn"
#    runLatencyTest "moses"
     runLatencyTest "masstree"
#    runLatencyTest "silo"
#    runLatencyTest "shore"
#    runLatencyTest "specjbb"
#    runLatencyTest "sphinx"
#    runLatencyTest "xapian"
}

getLatencyResultsSMRT(){
#    runLatencyTestSMRT "img-dnn"
#    runLatencyTestSMRT "moses"
     runLatencyTestSMRT "masstree"
#    runLatencyTestSMRT "silo"
#    runLatencyTestSMRT "shore"
#    runLatencyTestSMRT "specjbb"
#    runLatencyTestSMRT "sphinx"
#    runLatencyTestSMRT "xapian"
}
reset_prob_vm(){
    virsh shutdown $prob_vm
    sleep 50
    sudo bash ../utility/cleanon_startup.sh $prob_vm 32
    for i in {0..7};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done
    for i in {8..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 92))
        printf "what is happening man"
    done
    for i in {16..23};do
        sudo virsh vcpupin $prob_vm $i $((i + 24 ))
    done
    for i in {24..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 96 ))
    done
    ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
}


activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 8 -s 4 -u 4000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/cpu_profiler/setup_vcapacity.sh"
    ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/cpu_prober.out -i 200000 -p 80 -s 7000 &  " & 
    sleep 10
}


set_normal_mode(){
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $i
    done
    for i in {0..7};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done
    for i in {8..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 92))
    done
    for i in {16..23};do
        sudo virsh vcpupin $prob_vm $i $((i + 24 ))
    done
    for i in {24..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 96 ))
    done
    
    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 20))
    done
    for i in {8..15};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 92))
    done
    for i in {16..23};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 24 ))
    done
    for i in {24..31};do
        sudo virsh vcpupin $compete_vm_1 $i $((i + 96 ))
    done

    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $i
    done
}

set_interference_mode(){
    for i in {0..7};do
        sudo virsh vcpupin $prob_vm $i $((i + 20))
    done
    for i in {8..15};do
        sudo virsh vcpupin $prob_vm $i $((i + 92))
    done
    for i in {16..23};do
        sudo virsh vcpupin $prob_vm $i $((i + 24 ))
    done
    for i in {24..31};do
        sudo virsh vcpupin $prob_vm $i $((i + 96 ))
    done

    for i in {0..7};do
        sudo virsh vcpupin $compete_vm_2 $i $((i + 80))
    done
    sudo virsh vcpupin $prob_vm 21 38
    sudo virsh vcpupin $prob_vm 20 38
    sudo virsh vcpupin $compete_vm_1 21 21
    sudo virsh vcpupin $compete_vm_1 20 21
    sudo virsh vcpupin $prob_vm 22 39
    sudo virsh vcpupin $prob_vm 23 39
    sudo virsh vcpupin $compete_vm_1 22 40
    sudo virsh vcpupin $compete_vm_1 23 40
    sudo virsh vcpupin $prob_vm 24 125
    sudo virsh vcpupin $prob_vm 25 126
    sudo virsh vcpupin $compete_vm_1 25 125
    sudo virsh vcpupin $compete_vm_1 24 126
}


reset_prob_vm
windup_compete_vms
length=${#bench_1_[@]}
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
#ssh ubuntu@$compete_vm_1 "sudo killall sysbench"
for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    (
        while true; do
            set_normal_mode
            sleep 30
            set_interference_mode
            sleep 30
        done
    ) &
    mode_pid=$!
    ssh ubuntu@$prob_vm "$bench_1">>"${OUTPUT_FILE}_$i"
    sudo kill $mode_pid
done
getLatencyResults
activate_vprobers
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run"
length=${#bench_1_[@]}
for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    
    (
        while true; do
            set_normal_mode
            sleep 30
            set_interference_mode
            sleep 30
        done
    ) &
   mode_pid=$!
    ssh ubuntu@$prob_vm "$bench_1">>"${OUTPUT_FILE_PROBE}_$i"
    sudo kill $mode_pid
done
getLatencyResultsSMRT