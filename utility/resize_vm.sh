echo "this is a script to resize partition of a VM,excercise caution"
echo "Input Name of VM you wish to change"
read vm_name
virsh shutdown $vm_name
while true; do
    vm_state=$(virsh domstate "$vm")
    if [ "$vm_state" != "running" ]; then
        echo "VM is shutdown"
        break
    else
        echo "Waiting for VM to shutdown"
        sleep 3 
    fi
done

sudo virt-filesystems --long --parts --blkdevs -h -a /var/lib/libvirt/images/$vm_name.qcow2 
echo "Input desired partition to expand"
read partition
echo "INPUT NEW DEVICE SIZE(NOTE THIS MUST BE BIGGER THEN PREVIOUS DEVICE SIZE, AND PREVIOUSLY SPECIFIED PARTITION WILL GAIN THE EXTRA SIZE)"
read new_size
echo "Would you like to keep a backup? y/n"
read backup
sudo qemu-img create -f qcow2 outdisk $new_size
sudo virt-resize --expand $partition /var/lib/libvirt/images/$vm_name.qcow2 outdisk
mv /var/lib/libvirt/images/$vm_name.qcow2 /var/lib/libvirt/images/backup$vm_name.qcow2
mv outdisk /var/lib/libvirt/images/$vm_name.qcow2
if [ $backup -eq "n" ]; then
    rm -rf  /var/lib/libvirt/images/backup$vm_name.qcow2
fi

