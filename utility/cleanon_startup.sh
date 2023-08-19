#!/bin/bash

# Function to set the vCPU count for a VM if needed and restart if necessary
set_vcpu() {
    local vm=$1
    local target_vcpu_count=$2

    # Get the current vCPU counts
    local max_vcpu_count=$(virsh vcpucount "$vm" --maximum)

    # If the maximum vCPU count is different, set it and restart the VM (if it's running)
    if [ "$max_vcpu_count" -ne "$target_vcpu_count" ]; then
        if virsh list --state-running --name | grep -q "^$vm$"; then
            virsh shutdown "$vm"
            while virsh list --state-running --name | grep -q "^$vm$"; do
                sleep 2  # Waiting for the VM to shut down
            done
        fi

        # Set the vCPU count
        virsh setvcpus "$vm" "$target_vcpu_count" --config

        # Start the VM again if it was running before
        virsh start "$vm"
    fi
}

# Get a list of all running VMs
running_vms=$(virsh list --state-running --name)

# Process input arguments
while [ "$#" -gt 0 ]; do
    vm="$1"
    vcpu_count="$2"
    shift 2  # Shift past the VM and its vCPU count

    if ! echo "$running_vms" | grep -q "^$vm$"; then
        echo "Starting VM: $vm"
        virsh start "$vm"
    else
        echo "VM $vm is already running."
    fi

    # Set the vCPU count for the VM
    set_vcpu "$vm" "$vcpu_count"
done

# Shutdown VMs that weren't mentioned in the arguments
for running_vm in $running_vms; do
    if ! echo "$@" | grep -qw "$running_vm"; then
        echo "Shutting down VM: $running_vm"
        virsh shutdown "$running_vm"
    fi
done