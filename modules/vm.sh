#!/usr/bin/env bash

# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: delete_vm
#
# Delete a VM

delete_vm () {
  if [ "${iso['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${iso['exists']}" = "true" ]; then
      delete_kvm_vm
    else
      information_message "KVM VM ${iso['name']} does not exist"
    fi
  fi
}

# Function: create_ci_vm
#
# Create a VM for testing cloud init

create_ci_vm () {
  if [ "${iso['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${iso['exists']}" = "false" ]; then
      create_kvm_ci_vm
    else
      information_message "KVM VM ${iso['name']} already exists"
    fi
  fi
}

# Function: create_iso_vm
#
# Create a VM for testing an ISO

create_iso_vm () {
  if [ "${vm['inputfile']}" = "" ]; then
    if ! [ "${iso['outputfile']}" = "" ]; then
     iso['inputfile']="${iso['outputfile']}"
    fi
  fi
  if [ "${iso['type']}" = "kvm" ]; then
    check_kvm_vm_exists
    if [ "${iso['exists']}" = "false" ]; then
      create_kvm_iso_vm
    else
      information_message "KVM VM ${iso['name']} already exists"
    fi
  fi
}

# Function: list_vm
#
# List VMs

list_vm () {
  if [ "${iso['type']}" = "kvm" ]; then
    list_kvm_vm
  fi
}
