
prob_vm=$1
compete_vm=$2
benchmark_command="sysbench --threads=16 --time=3 cpu run"

sudo bash ../utility/cleanon_startup.sh $prob_vm 16
sudo bash ../utility/cleanon_startup.sh $compete_vm 16

bench_1_=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -- -a run -p dedup -n 16 -i native")
bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -- -a run -p streamcluster -n 16 -i native")
bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -- -a run -p bodytrack -n 16 -i native")
bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -- -a run -p ferret -n 16 -i native")
bench_1_+=("sudo /home/ubuntu/Workloads/par-bench/bin/parsecmgmt -- -a run -p canneal -n 16 -i native")

for i in {0..16};do
    sudo virsh vcpupin $prob_vm $i $((i))
    sudo virsh vcpupin $compete_vm $i $((i))
done


activate_vprobers(){
    ssh ubuntu@$prob_vm "sudo insmod /home/ubuntu/vsched/custom_modules/cust_topo.ko" 
    #ssh ubuntu@$prob_vm "sudo /home/ubuntu/vtop/a.out -f 8 -s 4 -u 4000" &
    ssh ubuntu@$prob_vm "sudo bash /home/ubuntu/runprober.sh"
    ssh ubuntu@$prob_vm "nohup sudo /home/ubuntu/cpu_profiler/a.out -i 20 -p 80 -s 10000 &  " & 
    sleep 10
}

OUTPUT_FILE="./data/n_smt_plc-$(date +%m%d%H%M).txt"

length=${#bench_1_[@]}
ssh ubuntu@$compete_vm "sudo sysbench --threads=16 --time=900000 cpu run &"&

activate_vprobers

for ((i=0; i<length; i++)); do
    bench_1=${bench_1_[$i]}
    #without IVH
    echo "Without IVH" >> "${OUTPUT_FILE}_$i"
    ssh ubuntu@$prob_vm "$bench_1">>"${OUTPUT_FILE}_$i"

    ssh ubuntu@$prob_vm "sudo /home/ubuntu/vsched/tools/bpf/vcfs/atc" &
    echo "With IVH" >> "${OUTPUT_FILE}_$i"
    ssh ubuntu@$prob_vm "$bench_1">>"${OUTPUT_FILE}_$i"
    ssh ubuntu@$prob_vm "sudo killall atc"
    sleep 10 
done