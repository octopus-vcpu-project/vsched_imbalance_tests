vm="e-vm1"
for i in {0..31};do
	virsh vcpupin e-vm1 $((i)) $((i))
done
