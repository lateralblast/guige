#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: delete_vm
#
# Delete a VM

delete_vm () {
  if [ "$VM_TYPE" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "$VM_EXISTS" = "true" ]; then
      delete_kvm_vm
    else
      information_message "KVM VM $VM_NAME does not exist"
    fi
  fi
}

# Function: create_ci_vm
#
# Create a VM for testing cloud init

create_ci_vm () {
  if [ "$VM_TYPE" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "$VM_EXISTS" = "false" ]; then
      create_kvm_ci_vm
    else
      information_message "KVM VM $VM_NAME already exists"
    fi
  fi
}

# Function: create_iso_vm
#
# Create a VM for testing an ISO

create_iso_vm () {
  if [ "$VM_ISO" = "" ]; then
    if ! [ "$ISO_OUTPUT_FILE" = "" ]; then
      VM_ISO="$ISO_OUTPUT_FILE"
    fi
  fi
  if [ "$VM_TYPE" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "$VM_EXISTS" = "false" ]; then
      create_kvm_iso_vm
    else
      information_message "KVM VM $VM_NAME already exists"
    fi
  fi
}

# Function: list_vm
#
# List VMs

list_vm () {
  if [ "$VM_TYPE" = "kvm" ]; then
    list_kvm_vm
  fi
}
