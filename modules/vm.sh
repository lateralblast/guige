#!/usr/bin/env bash

# shellcheck disable=SC2129

# Function: delete_vm
#
# Delete a VM

delete_vm () {
  if [ "${vm['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${vm['exists']}" = "true" ]; then
      delete_kvm_vm
    else
      information_message "KVM VM ${vm['name']} does not exist"
    fi
  fi
}

# Function: create_ci_vm
#
# Create a VM for testing cloud init

create_ci_vm () {
  if [ "${vm['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${vm['exists']}" = "false" ]; then
      create_kvm_ci_vm
    else
      information_message "KVM VM ${vm['name']} already exists"
    fi
  fi
}

# Function: create_iso_vm
#
# Create a VM for testing an ISO

create_iso_vm () {
  if [ "${vm['inputfile']}" = "" ]; then
    if ! [ "${iso['outputfile']}" = "" ]; then
      vm['inputfile']="${iso['outputfile']}"
    fi
  fi
  if [ "${vm['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${vm['exists']}" = "false" ]; then
      create_kvm_iso_vm
    else
      information_message "KVM VM ${vm['name']} already exists"
    fi
  fi
}

# Function: list_vm
#
# List VMs

list_vm () {
  if [ "${vm['type']}" = "kvm" ]; then
    list_kvm_vm
  fi
}
