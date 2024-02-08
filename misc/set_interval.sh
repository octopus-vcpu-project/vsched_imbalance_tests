VM_PATH="/sys/fs/cgroup/machine.slice/machine-qemu\x2d44\x2de\x2dvm1.scope/libvirt"
run_slice=$1
period=$2
for i in {0..31};do
	echo ${run_slice} ${period} > ${VM_PATH}/vcpu${i}/cpu.max
done
