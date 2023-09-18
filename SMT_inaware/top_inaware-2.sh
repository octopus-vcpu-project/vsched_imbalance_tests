declare -a io_benchmarks
io_benchmarks=("${io_benchmarks[@]}" "sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=50 fileio run")
io_benchmarks=("${io_benchmarks[@]}" "sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=50 fileio run")
io_benchmarks=("${io_benchmarks[@]}" "sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=50 fileio run")
io_benchmarks=("${io_benchmarks[@]}" "sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=50 fileio run")

prob_vm=$1
prob_vm=$1
cpu_benchmark="sysbench --threads=16 --time=50 cpu run"
io_benchmark="sysbench --file-test-mode=rndrw --threads=16 --file-total-size=10G --max-time=50 fileio run"
sudo bash ../utility/cleanon_startup.sh $prob_vm 32

for i in {0..15};do
    sudo virsh vcpupin $prob_vm  $i $i
done

for i in {16..31};do
    sudo virsh vcpupin $prob_vm $i $((i + 64))
done

ssh ubuntu@$prob_vm "sudo killall sysbench" 
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=20 cpu run" 
#topology naive testing
OUTPUT_FILE="./tests/top_inaware_2_naive$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo $cpu_benchmark" > "$OUTPUT_FILE" & 
ssh ubuntu@$prob_vm "sudo $io_benchmark" > "$OUTPUT_FILE" 
sleep 2
ssh ubuntu@$prob_vm "sudo sysbench --threads=32 --time=10 cpu run" 
#topology smart testing
OUTPUT_FILE2="./tests/top_inaware_2_smart$(date +%m%d%H%M).txt"
ssh ubuntu@$prob_vm "sudo taskset -c 0-15 $cpu_benchmark" >> "$OUTPUT_FILE2" &
ssh ubuntu@$prob_vm "sudo taskset -c 16-31 $io_benchmark" >> "$OUTPUT_FILE2"  
