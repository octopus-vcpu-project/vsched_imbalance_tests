vm="e-vm1"
for i in {0..15};do
	virsh vcpupin e-vm1 $((i)) $((i))
done
for i in {0..15};do
        virsh vcpupin e-vm3 $((i)) $((i))
done
