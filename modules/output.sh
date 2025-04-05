#!/usr/bin/env bash

# shellcheck disable=SC2001
# shellcheck disable=SC2129
# shellcheck disable=SC2154

# Function: execute_command
#
# Execute a command

execute_command () {
  command="$1"
  execute_message "${command}"
  if [ "${options['testmode']}" = "false" ]; then
    eval "${command}"
  fi
}

# Function: print_file
#
# Print contents of file

print_file () {
  file_name="$1"
  echo ""
  handle_output "# Contents of file ${file_name}" "TEXT"
  echo ""
  if [ "${options['testmode']}" = "false" ]; then
    cat "${file_name}"
  fi
}

# Function: execute_message
#
#  Print command

execute_message () {
  output_text="$1"
  output_type="COMMAND"
  handle_output "${output_text}" "${output_type}"
}

# Function: information_message
#
# Print informational message

information_message () {
  output_text="$1"
  output_type="TEXT"
  handle_output "# Information: ${output_text}" "${output_type}"
}

# Function: verbose_message
#
# Print verbose message

verbose_message () {
  output_text="$1"
  output_type="TEXT"
  temp['verbose']="true"
  handle_output "${output_text}" "${output_type}"
  temp['verbose']="false"
}

# Function: warning_message
#
# Print warning message

warning_message () {
  output_text="$1"
  output_type="TEXT"
  temp['verbose']="true"
  handle_output "# Warning: ${output_text}" "${output_type}"
  temp['verbose']="false"
}

# Function: handle_output
#
# Handle text output

handle_output () {
  output_text="$1"
  output_type="$2"
  if [ "${options['verbose']}" = "true" ] || [ "${temp['verbose']}" = "true" ]; then
    if [ "${options['testmode']}" = "true" ]; then
      echo "${output_text}"
    else
      if [ "${output_type}" = "TEXT" ]; then
        echo "${output_text}"
      else
        echo "# Executing: ${output_text}"
      fi
    fi
  fi
}

# Function: sudo_chown
#
# Change ownership

sudo_chown () {
  object="$1"
  user="$2"
  group="$3"
  handle_output "# Checking ownership of ${object} is ${user}:${group}" "TEXT"
  if [ "${options['testmode']}" = "false" ]; then
    if [ ! -f "/.dockerenv" ]; then
      sudo chown "${user}":"${group}" "${object}"
    fi
  fi
}

# Function: create_dir
#
# Create directory

create_dir () {
  create_dir="$1"
  handle_output "# Checking directory ${create_dir} exists" "TEXT"
  if [ ! -d "${create_dir}" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      mkdir -p "${create_dir}"
    fi
  fi
}

# Function: sudo_create_dir
#
# Create directory

sudo_create_dir () {
  create_dir="$1"
  handle_output "# Checking directory ${create_dir} exists" "TEXT"
  if [ ! -d "${create_dir}" ]; then
    if [ "${options['testmode']}" = "false" ]; then
      if [ -f "/.dockerenv" ]; then
        mkdir -p "${create_dir}"
      else
        sudo mkdir -p "${create_dir}"
      fi
    fi
  fi
}

# Function: delete_dir
#
# Remove directory

delete_dir () {
  delete_dir="$1"
  handle_output "# Checking directory ${delete_dir} exists" "TEXT"
  if [ ! "${delete_dir}" = "/" ]; then
    if [[ ${delete_dir} =~ [0-9a-zA-Z] ]]; then
      if [ -d "${delete_dir}" ]; then
        if [ "${options['testmode']}" = "false" ]; then
          sudo rm -f "${delete_dir}"
        fi
      fi
    fi
  fi
}

# Function: check_workdir
#
# Check work directories exist
#
# Example:
# mkdir -p ./isomount ./isonew/squashfs ./isonew/cd ./isonew/custom

check_workdir () {
  handle_output "# Check work directories" "TEXT"
  for iso_dir in ${iso['mountdir']} ${iso['newdir']}/squashfs ${iso['newdir']}/mksquash ${iso['newdir']}/cd ${iso['newdir']}/custom ${iso['workdir']}/bin ${iso['workdir']}/files; do
    handle_output "# Check directory ${iso_dir} exists" "TEXT"
    if [ "${options['force']}" = "true" ]; then
      delete_dir "${iso_dir}"
    fi
    create_dir "${iso_dir}"
  done
}

# Function: check_old_workdir
#
# Check old release work directory
# Used when copying files from old release to a new release

check_old_workdir () {
  handle_output "# Check old release work directories exist" "TEXT"
  for iso_dir in ${old['mountdir']} ${old['workdir']}/files; do
    if [ "${options['force']}" = "true" ]; then
      delete_dir "${iso_dir}"
    fi
    create_dir "${iso_dir}"
  done
}

# Function: check_file_perms
#
# Check file permissions of file

check_file_perms () {
  check_file="$1"
  handle_output "# Checking file permissions for ${check_file}" "TEXT"
  if [ -f "${check_file}" ]; then
    my_user="${os['user']}"
    my_group=$(groups |awk '{print $1}')
    file_user=$(find "${iso['outputfile']}" -ls |awk '{print $5}')
    if [ ! "${file_user}" = "${my_user}" ]; then
      sudo chown "${my_user}" "${check_file}"
      sudo chgrp "${my_group}" "${check_file}"
    fi
  fi
}

# Function: create_export
#
# Setup NFS server to export ISO

create_export () {
  nfs_dir="${iso['workdir']}/files"
  exports_file="/etc/exports"
  handle_output "# Check NFS export is enabled" "TEXT"
  if [ -f "${exports_file}" ]; then
    export_check=$( grep -v "^#" < "${exports_file}" |grep "${nfs_dir}" |grep "${iso['bmcip']}" |awk '{print $1}' | head -1 )
  else
    export_check=""
  fi
  if [ -z "${export_check}" ]; then
    if [ "${os['name']}" = "Darwin" ]; then
      echo "${nfs_dir} --mapall=${os['user']} ${iso['bmcip']}" |sudo tee -a "${exports_file}"
      sudo nfsd enable
      sudo nfsd restart
    else
      echo "${nfs_dir} ${iso['bmcip']}(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)" |sudo tee -a "${exports_file}"
      sudo exportfs -a
    fi
    print_file "${exports_file}"
  fi
}

# Function: update_output_file_name
#
# Update output file name based on switched and options

update_output_file_name () {
  if ! [ "${iso['hostname']}" = "${defaults['hostname']}" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['hostname']}.iso"
  fi
  if ! [ "${iso['nic']}" = "${defaults['nic']}" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['nic']}.iso"
  fi
  if [ "${options['dhcp']}" = "false" ]; then
    if ! [ "${iso['ip']}" = "${defaults['ip']}" ]; then
      temp_dir_name=$( dirname "${iso['outputfile']}" )
      temp_file_name=$( basename "${iso['outputfile']}" .iso )
      iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['ip']}.iso"
    fi
    if ! [ "${iso['gateway']}" = "${defaults['gateway']}" ]; then
      temp_dir_name=$( dirname "${iso['outputfile']}" )
      temp_file_name=$( basename "${iso['outputfile']}" .iso )
      iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['gateway']}.iso"
    fi
    if ! [ "${iso['dns']}" = "${defaults['dns']}" ]; then
      temp_dir_name=$( dirname "${iso['outputfile']}" )
      temp_file_name=$( basename "${iso['outputfile']}" .iso )
      iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['dns']}.iso"
    fi
  fi
  if ! [ "${iso['username']}" = "${defaults['username']}" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['username']}.iso"
  fi
  if ! [ "${iso['disk']}" = "${defaults['disk']}" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['disk']}.iso"
  fi
  if ! [ "${iso['prefix']}" = "" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${iso['prefix']}-${temp_file_name}.iso"
  fi
  if ! [ "${iso['suffix']}" = "" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-${iso['suffix']}.iso"
  fi
  if [[ "${iso['options']}" =~ "cluster" ]]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-cluster.iso"
  fi
  if [[ "${iso['options']}" =~ "kvm" ]]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-kvm.iso"
  fi
  if [[ "${iso['options']}" =~ "biosdevname" ]]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-biosdevname.iso"
  fi
  if [ "${options['sshkey']}" = "true" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-sshkey.iso"
  fi
  if [ "${options['nvme']}" = "true" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-nvme.iso"
  fi
  if [ "${options['dhcp']}" = "true" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-dhcp.iso"
  fi
  if [ "${options['autoinstall']}" = "true" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-custom-user-data.iso"
  fi
  if [ "${options['grubfile']}" = "true" ]; then
    temp_dir_name=$( dirname "${iso['outputfile']}" )
    temp_file_name=$( basename "${iso['outputfile']}" .iso )
    iso['outputfile']="${temp_dir_name}/${temp_file_name}-custom-grub.iso"
  fi
  for VOLMGR in ${iso['volumemanager']}; do
    if [ ! "$VOLMGR" = "custom" ]; then
      temp_dir_name=$( dirname "${iso['outputfile']}" )
      temp_file_name=$( basename "${iso['outputfile']}" .iso )
      iso['outputfile']="${temp_dir_name}/${temp_file_name}-$VOLMGR.iso"
    fi
  done
  if [ "${options['createisovm']}" = "true" ] || [ "${options['createcivm']}" = "true" ]; then
    if [ "${vm['type']}" = "kvm" ]; then
      if [ "${os['name']}" = "Darwin" ]; then
        options['requiredpackages']="${options['requiredpackages']} qemu libvirt dnsmasq libosinfo virt-manager"
      else
        options['requiredpackages']="${options['requiredpackages']} qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs ebtables vde2 openbsd-netcat cloud-image-utils libosinfo"
      fi
    fi
  fi
  if [ "${vm['type']}" = "" ]; then
    vm['type']="${defaults['vmtype']}"
  fi
  if [ "${vm['nic']}" = "" ]; then
    vm['nic']="${defaults['vmnic']}"
  fi
  if [ "${vm['size']}" = "" ]; then
    vm['size']="${defaults['vmsize']}"
  fi
  if [ "${vm['cpus']}" = "" ]; then
    vm['cpus']="${defaults['vmcpus']}"
  fi
  if [[ "${iso['action']}" =~ "vm" ]]; then
    if [[ "${iso['action']}" =~ "create" ]]; then
      if [ "${vm['ram']}" = "" ]; then
        vm['ram']="${defaults['vmram']}"
      else
        if [[ "${vm['ram']}" =~ "G" ]] || [[ "${vm['ram']}" =~ "g" ]]; then
          vm['ram']=$(echo "${vm['ram']}" |sed "s/[G,g]//g")
          vm['ram']=$(echo "${vm['ram']}*1024*1024" |bc -l)
        fi
        if [ "${vm['ram']}" -lt 1024000 ]; then
          warning_message "Insufficient RAM specified for VM"
          exit
        fi
      fi
    fi
    if [ "${vm['name']}" = "" ]; then
      if [ "${iso['build']}" = "" ]; then
        if [[ "${iso['action']}" =~ "ci" ]]; then
          vm['name']="${script['name']}-ci-${iso['osname']}-${iso['release']}-${iso['boottype']}-${iso['arch']}"
        else
          vm['name']="${script['name']}-iso-${iso['osname']}-${iso['release']}-${iso['boottype']}-${iso['arch']}"
        fi
      else
        if [[ "${iso['action']}" =~ "ci" ]]; then
          vm['name']="${script['name']}-ci-${iso['osname']}-${iso['build']}-${iso['release']}-${iso['boottype']}-${iso['arch']}"
        else
          vm['name']="${script['name']}-iso-${iso['osname']}-${iso['build']}-${iso['release']}-${iso['boottype']}-${iso['arch']}"
        fi
      fi
    fi
    if [[ "${iso['action']}" =~ "create" ]]; then
      if ! [ "${vm['inputfile']}" = "" ]; then
        if ! [ -f "${vm['inputfile']}" ]; then
          warning_message "ISO ${vm['inputfile']} does not exist"
          exit
        fi
      fi
    fi
  fi
  if [ "${options['serial']}" = "true" ]; then
    iso['kernelargs']="${iso['kernel']}ARGS console=${iso['serialporta']},${iso['serialportspeeda']}"
    if ! [ "${iso['serailportb']}" = "" ]; then
      iso['kernelargs']="${iso['kernel']}ARGS console=${iso['serailportb']},${iso['serialportspeedb']}"
    fi
  fi
  if [ "${old['installsquashfile']}" = "" ]; then
    old['installsquashfile']="${defaults['oldinstallsquashfsfile']}"
  fi
  if [ "${old['workdir']}" = "" ]; then
    old['workdir']="${defaults['oldworkdir']}"
  fi
  if [ "${vm['inputfile']}" = "" ]; then
    vm['inputfile']="${iso['outputfile']}"
  fi
}
